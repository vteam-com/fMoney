// ignore_for_file: always_put_control_body_on_new_line, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:money/core/widgets/csv_column_mapper_dialog.dart';
import 'package:money/core/widgets/xlsx_header_row_selector_dialog.dart';
import 'package:money/data/storage/import/import_data.dart';

// Simple, dependency-free XLSX parser (only one sheet, static values)
Future<void> importXLSX(BuildContext context, String filePath) async {
  try {
    final File file = File(filePath);
    final Uint8List bytes = await file.readAsBytes();
    final Archive archive = ZipDecoder().decodeBytes(bytes);

    for (final ArchiveFile file in archive) {
      debugPrint(file.name);
    }

    // Extract sharedStrings.xml if available
    List<String> sharedStrings = <String>[];
    final ArchiveFile? sharedFile = archive.findFile('xl/sharedStrings.xml');
    if (sharedFile != null) {
      String xml;
      try {
        xml = utf8.decode(sharedFile.content, allowMalformed: true);
      } catch (_) {
        xml = latin1.decode(sharedFile.content, allowInvalid: true);
      }
      // Match both <t> and namespaced <x:t> or <r><t> etc.
      final RegExp sharedStringRegex = RegExp(r'<(?:\w+:)?t[^>]*>(.*?)</(?:\w+:)?t>', dotAll: true);

      // Extract text from all <t> tags, flattening nested ones
      sharedStrings = sharedStringRegex.allMatches(xml).map((RegExpMatch m) => m.group(1)).whereType<String>().map((
        String text,
      ) {
        text = text
            .replaceAll('\r', '')
            .replaceAll('\n', '')
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'");
        return text.trim();
      }).toList();

      debugPrint('Shared strings loaded: ${sharedStrings.length}');
      if (sharedStrings.isNotEmpty) {
        debugPrint('Example shared strings:\n${sharedStrings.take(10).join('\n')}');
      }
    } else {
      debugPrint('Shared strings file not found');
    }

    // Extract first sheet*.xml
    final ArchiveFile sheetFile = archive.files.firstWhere(
      (ArchiveFile file) => RegExp(r'^xl/worksheets/sheet.*\.xml$').hasMatch(file.name),
      orElse: () => ArchiveFile('', 0, <int>[]),
    );

    if (sheetFile.name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No sheet XML found in XLSX file.')),
      );
      return;
    }

    final String sheetXml = utf8.decode(sheetFile.content, allowMalformed: true);

    // Find all rows and process them
    final RegExp rowRegex = RegExp(r'<(?:\w+:)?row[^>]*>(.*?)</(?:\w+:)?row>', dotAll: true);
    final RegExp cellRegex = RegExp(r'<(?:\w+:)?c[^>]*?(?:t="(?<t>[^"]+)")?[^>]*?>(.*?)</(?:\w+:)?c>', dotAll: true);
    final RegExp valueRegex = RegExp(r'<(?:\w+:)?v[^>]*>(.*?)</(?:\w+:)?v>', dotAll: true);

    debugPrint('Parsing worksheet XML...');
    final List<List<String>> worksheetData = <List<String>>[];
    for (final RegExpMatch rowMatch in rowRegex.allMatches(sheetXml)) {
      final String rowXml = rowMatch.group(1) ?? '';
      final List<String> rowData = <String>[];

      // Parse each cell in this row
      for (final RegExpMatch cellMatch in cellRegex.allMatches(rowXml)) {
        final String? cellType = cellMatch.namedGroup('t');
        final String cellXml = cellMatch.group(2) ?? '';
        String value = '';

        // Extract value from <v> tag
        final RegExpMatch? vMatch = valueRegex.firstMatch(cellXml);
        if (vMatch != null) {
          value = vMatch.group(1)?.trim() ?? '';

          // Try resolving shared string even when type is null but looks like an index
          final int? idx = int.tryParse(value);
          if (cellType == 's' || (idx != null && idx >= 0 && idx < sharedStrings.length)) {
            value = sharedStrings[idx!];
            debugPrint('Resolved shared string index $idx → "$value"');
          } else {
            debugPrint('Direct value: $value');
          }
        } else {
          // Handle inline strings: <is><t>Text</t></is>
          final RegExpMatch? inlineMatch = RegExp(
            r'<(?:\w+:)?is[^>]*>.*?<(?:\w+:)?t[^>]*>(.*?)</(?:\w+:)?t>.*?</(?:\w+:)?is>',
            dotAll: true,
          ).firstMatch(cellXml);
          if (inlineMatch != null) {
            value = inlineMatch.group(1)?.trim() ?? '';
            debugPrint('Found inline string: $value');
          } else {
            debugPrint('No value or inline string found');
          }
        }

        // Decode XML entities and Portuguese characters
        value = value
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'")
            .replaceAll('&#xE7;', 'ç')
            .replaceAll('&#xE3;', 'ã')
            .replaceAll('&#xE9;', 'é')
            .replaceAll('&#xEA;', 'ê')
            .replaceAll('&#xF5;', 'õ')
            .replaceAll('&#xF3;', 'ó');

        // Convert Excel serial date to readable date if value looks like one
        final double? excelDate = double.tryParse(value);
        if (excelDate != null && excelDate > 20000 && excelDate < 60000) {
          // Excel’s day 1 = 1900-01-01 (Excel bug means 1900-02-29 exists)
          final DateTime baseDate = DateTime(1899, 12, 30);
          final DateTime convertedDate = baseDate.add(Duration(days: excelDate.floor()));
          value =
              '${convertedDate.year}-${convertedDate.month.toString().padLeft(2, '0')}-${convertedDate.day.toString().padLeft(2, '0')}';
          debugPrint('Converted Excel date $excelDate → $value');
        }
        rowData.add(value);
      }

      // Add all rows, including potentially empty but positioned first rows
      worksheetData.add(rowData);
    }

    debugPrint('Before filtering: ${worksheetData.length} rows');
    if (worksheetData.isNotEmpty) {
      debugPrint('First few raw rows:');
      for (int i = 0; i < worksheetData.length && i < 5; i++) {
        debugPrint('  Row $i: ${worksheetData[i]}');
      }
    }

    // Filter out completely empty rows, but keep rows that might be headers
    final List<List<String>> filteredData = worksheetData
        .where((List<String> row) => row.isNotEmpty && row.any((String cell) => cell.trim().isNotEmpty))
        .toList();

    debugPrint('After filtering empty rows: ${filteredData.length} rows');
    if (filteredData.length < worksheetData.length) {
      debugPrint('Some rows were filtered out as empty');
    }

    if (filteredData.isEmpty) {
      debugPrint('ERROR: No valid data rows found after filtering');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('XLSX file contains no valid data.')),
      );
      return;
    }

    worksheetData.clear();
    worksheetData.addAll(filteredData);

    if (worksheetData.isEmpty) {
      debugPrint('ERROR: Worksheet data is empty after filtering');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('XLSX file contains no data rows.')),
      );
      return;
    }

    debugPrint('Final worksheet data: ${worksheetData.length} rows');
    debugPrint('Preview of data:');
    for (int i = 0; i < worksheetData.length && i < 5; i++) {
      debugPrint('  Row $i: ${worksheetData[i]}');
    }

    // Prompt user to select the header row
    final int? headerRowIndex = await showXlsxHeaderRowSelectorDialog(
      context: context,
      rows: worksheetData.length > 10 ? worksheetData.sublist(0, 10) : worksheetData,
    );
    if (headerRowIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('XLSX import cancelled.')),
      );
      return;
    }

    // Use selected row as headers, but generate meaningful names if they look like data
    List<String> headers = worksheetData[headerRowIndex];
    final List<String> meaningfulHeaders = <String>[];

    for (int i = 0; i < headers.length; i++) {
      final String header = headers[i].trim();

      // If header is empty, numeric, or looks like data (date or number), create a generic name
      if (header.isEmpty || DateTime.tryParse(header) != null || double.tryParse(header.replaceAll(',', '')) != null) {
        meaningfulHeaders.add('Column ${i + 1}');
      } else {
        meaningfulHeaders.add(header);
      }
    }

    headers = meaningfulHeaders;
    final List<List<String>> dataRows = worksheetData.skip(headerRowIndex + 1).toList();

    if (dataRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('XLSX file contains no data rows.')),
      );
      return;
    }

    final List<List<String>> previewRows = dataRows.length > 5 ? dataRows.sublist(0, 5) : dataRows;

    final Map<String, String>? columnMapping = await showCsvColumnMapperDialog(
      context: context,
      headers: headers,
      dataRows: previewRows,
    );

    if (columnMapping != null) {
      final ImportData importData = loadXLSX(headers, dataRows, columnMapping);
      if (importData.entries.isNotEmpty) {
        showAndConfirmTransactionToImport(context, importData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid entries found in XLSX to import.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('XLSX import cancelled.')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error importing XLSX: $e')),
    );
  }
}

ImportData loadXLSX(
  List<String> headers,
  List<List<String>> dataRows,
  Map<String, String> columnMapping,
) {
  final ImportData importData = ImportData();
  importData.fileType = 'XLSX';

  final String dateColumnName = columnMapping['date']!;
  final String descriptionColumnName = columnMapping['description']!;
  final String amountColumnName = columnMapping['amount']!;

  debugPrint('Loading XLSX data...');
  debugPrint('Headers: $headers');
  debugPrint('Column mapping: $columnMapping');
  debugPrint('Processing ${dataRows.length} data rows');

  final int dateIndex = headers.indexOf(dateColumnName);
  final int descriptionIndex = headers.indexOf(descriptionColumnName);
  final int amountIndex = headers.indexOf(amountColumnName);

  debugPrint('Column indices: date=$dateIndex, description=$descriptionIndex, amount=$amountIndex');

  if (dateIndex == -1 || descriptionIndex == -1 || amountIndex == -1) {
    debugPrint('ERROR: Column mapping failed - could not find required columns');
    return importData;
  }

  int processedRows = 0;
  int skippedRows = 0;
  int validRows = 0;

  for (int i = 0; i < dataRows.length; i++) {
    processedRows++;
    final List<String> row = dataRows[i];

    final int maxIndex = <int>[dateIndex, descriptionIndex, amountIndex].reduce((int a, int b) => a > b ? a : b);
    if (row.length <= maxIndex) {
      debugPrint('Row ${i + 1}: Skipped - insufficient columns (${row.length} vs required ${maxIndex + 1})');
      skippedRows++;
      continue;
    }

    // Debug: Show values for this row
    final String rawDate = row[dateIndex].trim();
    final String rawDescription = row[descriptionIndex].trim();
    final String rawAmount = row[amountIndex].trim();

    debugPrint('Row ${i + 1}: Date="$rawDate", Desc="$rawDescription", Amount="$rawAmount"');

    DateTime? date;
    try {
      date = _parseFlexibleDate(rawDate);
      if (date == null) {
        throw const FormatException('Could not parse date');
      }
    } catch (e) {
      debugPrint('Row ${i + 1}: Skipped - invalid date format: "$rawDate"');
      skippedRows++;
      continue;
    }

    if (rawDescription.isEmpty) {
      debugPrint('Row ${i + 1}: Skipped - empty description');
      skippedRows++;
      continue;
    }

    double? amount;
    try {
      final String amountStr = rawAmount.replaceAll(',', ''); // Handle common number formats
      amount = double.tryParse(amountStr);
      if (amount == null) {
        debugPrint('Row ${i + 1}: Skipped - invalid amount: "$rawAmount"');
        skippedRows++;
        continue;
      }
    } catch (e) {
      debugPrint('Row ${i + 1}: Skipped - amount parsing error: "$rawAmount"');
      skippedRows++;
      continue;
    }

    debugPrint('Row ${i + 1}: Successfully added entry - Date: ${date.toIso8601String()}, Amount: $amount');
    validRows++;

    importData.entries.add(
      ImportEntry(
        date: date,
        name: rawDescription,
        amount: amount,
        type: 'XLSXImport',
        fitid: 'xlsx_row_${i + 1}_${date.millisecondsSinceEpoch}',
        memo: '',
        number: '',
        stockAction: '',
        stockSymbol: '',
        stockQuantity: 0.0,
        stockPrice: 0.0,
        stockCommission: 0.0,
      ),
    );
  }

  debugPrint('Processing summary: $processedRows total rows, $validRows valid, $skippedRows skipped');
  debugPrint('Final: ${importData.entries.length} entries added to import data');

  return importData;
}

/// Parses dates in multiple common formats:
/// - ISO format: YYYY-MM-DD (2023-01-01)
/// - European format: DD/MM/YYYY (30/06/2025)
/// - US format: MM/DD/YYYY (06/30/2025)
/// - Short year formats: DD/MM/YY (30/06/25)
DateTime? _parseFlexibleDate(String dateStr) {
  dateStr = dateStr.trim();
  if (dateStr.isEmpty) {
    return null;
  }

  // Try ISO format first (Dart's native format)
  try {
    return DateTime.parse(dateStr);
  } catch (_) {
    // Continue to other formats
  }

  // Try European format: DD/MM/YYYY or DD/MM/YY
  final RegExp euroFormat = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2,4})$');
  final RegExpMatch? euroMatch = euroFormat.firstMatch(dateStr);
  if (euroMatch != null) {
    final int day = int.parse(euroMatch.group(1)!);
    final int month = int.parse(euroMatch.group(2)!);
    final int yearStr = int.parse(euroMatch.group(3)!);

    // Handle 2-digit years
    final int year = yearStr < 100 ? (yearStr < 50 ? 2000 + yearStr : 1900 + yearStr) : yearStr;

    try {
      return DateTime(year, month, day);
    } catch (_) {
      // Invalid date
      return null;
    }
  }

  // Try US format: MM/DD/YYYY or MM/DD/YY
  final RegExp usFormat = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2,4})$');
  final RegExpMatch? usMatch = usFormat.firstMatch(dateStr);
  if (usMatch != null) {
    final int month = int.parse(usMatch.group(1)!);
    final int day = int.parse(usMatch.group(2)!);
    final int yearStr = int.parse(usMatch.group(3)!);

    // Handle 2-digit years
    final int year = yearStr < 100 ? (yearStr < 50 ? 2000 + yearStr : 1900 + yearStr) : yearStr;

    try {
      return DateTime(year, month, day);
    } catch (_) {
      // Invalid date
      return null;
    }
  }

  // Try YYYY/MM/DD format (sometimes used internationally)
  final RegExp ymdFormat = RegExp(r'^(\d{4})/(\d{1,2})/(\d{1,2})$');
  final RegExpMatch? ymdMatch = ymdFormat.firstMatch(dateStr);
  if (ymdMatch != null) {
    final int year = int.parse(ymdMatch.group(1)!);
    final int month = int.parse(ymdMatch.group(2)!);
    final int day = int.parse(ymdMatch.group(3)!);

    try {
      return DateTime(year, month, day);
    } catch (_) {
      // Invalid date
      return null;
    }
  }

  // No valid format found
  return null;
}
