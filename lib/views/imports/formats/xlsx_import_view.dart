// ignore_for_file: always_put_control_body_on_new_line, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_logger_helper.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/views/imports/shared/data_import_view.dart';
import 'package:money/widgets/dialogs/csv_column_mapper_dialog.dart';
import 'package:money/widgets/dialogs/xlsx_header_row_selector_dialog.dart';

const int _zeroInt = 0;
const int _oneInt = 1;
const int _twoInt = 2;
const int _threeInt = 3;
const int _unsetIndex = -1;
const double _zeroDouble = 0.0;
const int _headerPreviewCount = 10;
const int _previewRowLimit = 5;
const int _datePadWidth = 2;
const String _datePadChar = '0';
const int _excelDateMin = 20000;
const int _excelDateMax = 60000;
const int _excelBaseYear = 1899;
const int _excelBaseMonth = 12;
const int _excelBaseDay = 30;
const int _twoDigitYearMax = 100;
const int _twoDigitYearPivot = 50;
const int _yearBaseRecent = 2000;
const int _yearBasePast = 1900;

// Simple, dependency-free XLSX parser (only one sheet, static values)
/// Imports XLSX file and parses transaction data from Excel format.
Future<void> importXLSX(BuildContext context, String filePath) async {
  try {
    final File file = File(filePath);
    final Uint8List bytes = await file.readAsBytes();
    final Archive archive = ZipDecoder().decodeBytes(bytes);

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
      sharedStrings = sharedStringRegex
          .allMatches(xml)
          .map((RegExpMatch m) => m.group(_oneInt))
          .whereType<String>()
          .map((
            String text,
          ) {
            text = text
                .replaceAll('\r', '')
                .replaceAll('\n', '')
                .replaceAll(SharedStrings.xmlEntityAmp, '&')
                .replaceAll(SharedStrings.xmlEntityLt, '<')
                .replaceAll(SharedStrings.xmlEntityGt, '>')
                .replaceAll(SharedStrings.xmlEntityQuot, '"')
                .replaceAll(SharedStrings.xmlEntityApos, "'");
            return text.trim();
          })
          .toList();
    }

    // Extract first sheet*.xml
    final ArchiveFile sheetFile = archive.files.firstWhere(
      (ArchiveFile file) => RegExp(r'^xl/worksheets/sheet.*\.xml$').hasMatch(file.name),
      orElse: () => ArchiveFile('', _zeroInt, <int>[]),
    );

    if (sheetFile.name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.tr(AppTranslationKeys.noSheetXmlFoundInXlsxFile))),
      );
      return;
    }

    final String sheetXml = utf8.decode(sheetFile.content, allowMalformed: true);

    // Find all rows and process them
    final RegExp rowRegex = RegExp(r'<(?:\w+:)?row[^>]*>(.*?)</(?:\w+:)?row>', dotAll: true);
    final RegExp cellRegex = RegExp(r'<(?:\w+:)?c[^>]*?(?:t="(?<t>[^"]+)")?[^>]*?>(.*?)</(?:\w+:)?c>', dotAll: true);
    final RegExp valueRegex = RegExp(r'<(?:\w+:)?v[^>]*>(.*?)</(?:\w+:)?v>', dotAll: true);

    final List<List<String>> worksheetData = <List<String>>[];
    for (final RegExpMatch rowMatch in rowRegex.allMatches(sheetXml)) {
      final String rowXml = rowMatch.group(_oneInt) ?? '';
      final List<String> rowData = <String>[];

      // Parse each cell in this row
      for (final RegExpMatch cellMatch in cellRegex.allMatches(rowXml)) {
        final String? cellType = cellMatch.namedGroup('t');
        final String cellXml = cellMatch.group(_twoInt) ?? '';
        String value = '';

        // Extract value from <v> tag
        final RegExpMatch? vMatch = valueRegex.firstMatch(cellXml);
        if (vMatch != null) {
          value = vMatch.group(_oneInt)?.trim() ?? '';

          // Try resolving shared string even when type is null but looks like an index
          final int? idx = int.tryParse(value);
          if (cellType == 's' || (idx != null && idx >= _zeroInt && idx < sharedStrings.length)) {
            value = sharedStrings[idx!];
          }
        } else {
          // Handle inline strings: <is><t>Text</t></is>
          final RegExpMatch? inlineMatch = RegExp(
            r'<(?:\w+:)?is[^>]*>.*?<(?:\w+:)?t[^>]*>(.*?)</(?:\w+:)?t>.*?</(?:\w+:)?is>',
            dotAll: true,
          ).firstMatch(cellXml);
          if (inlineMatch != null) {
            value = inlineMatch.group(_oneInt)?.trim() ?? '';
          }
        }

        // Decode XML entities and Portuguese characters
        value = value
            .replaceAll(SharedStrings.xmlEntityAmp, '&')
            .replaceAll(SharedStrings.xmlEntityLt, '<')
            .replaceAll(SharedStrings.xmlEntityGt, '>')
            .replaceAll(SharedStrings.xmlEntityQuot, '"')
            .replaceAll(SharedStrings.xmlEntityApos, "'")
            .replaceAll(SharedStrings.xmlEntityCedilla, 'ç')
            .replaceAll(SharedStrings.xmlEntityATilde, 'ã')
            .replaceAll(SharedStrings.xmlEntityEAcute, 'é')
            .replaceAll(SharedStrings.xmlEntityECirc, 'ê')
            .replaceAll(SharedStrings.xmlEntityOTilde, 'õ')
            .replaceAll(SharedStrings.xmlEntityOAcute, 'ó');

        // Convert Excel serial date to readable date if value looks like one
        final double? excelDate = double.tryParse(value);
        if (excelDate != null && excelDate > _excelDateMin && excelDate < _excelDateMax) {
          // Excel’s day 1 = 1900-01-01 (Excel bug means 1900-02-29 exists)
          final DateTime baseDate = DateTime(_excelBaseYear, _excelBaseMonth, _excelBaseDay);
          final DateTime convertedDate = baseDate.add(Duration(days: excelDate.floor()));
          value =
              '${convertedDate.year}-${convertedDate.month.toString().padLeft(_datePadWidth, _datePadChar)}-${convertedDate.day.toString().padLeft(_datePadWidth, _datePadChar)}';
        }
        rowData.add(value);
      }

      // Add all rows, including potentially empty but positioned first rows
      worksheetData.add(rowData);
    }

    // Filter out completely empty rows, but keep rows that might be headers
    final List<List<String>> filteredData = worksheetData
        .where((List<String> row) => row.isNotEmpty && row.any((String cell) => cell.trim().isNotEmpty))
        .toList();

    if (filteredData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.tr(AppTranslationKeys.xlsxFileContainsNoValidData))),
      );
      return;
    }

    worksheetData.clear();
    worksheetData.addAll(filteredData);

    if (worksheetData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.tr(AppTranslationKeys.xlsxFileContainsNoDataRows))),
      );
      return;
    }

    // Prompt user to select the header row
    final int? headerRowIndex = await showXlsxHeaderRowSelectorDialog(
      context: context,
      rows: worksheetData.length > _headerPreviewCount
          ? worksheetData.sublist(_zeroInt, _headerPreviewCount)
          : worksheetData,
    );
    if (headerRowIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.tr(AppTranslationKeys.xlsxImportCancelled))),
      );
      return;
    }

    // Use selected row as headers, but generate meaningful names if they look like data
    List<String> headers = worksheetData[headerRowIndex];
    final List<String> meaningfulHeaders = <String>[];

    for (int i = _zeroInt; i < headers.length; i++) {
      final String header = headers[i].trim();

      // If header is empty, numeric, or looks like data (date or number), create a generic name
      if (header.isEmpty || DateTime.tryParse(header) != null || double.tryParse(header.replaceAll(',', '')) != null) {
        meaningfulHeaders.add(
          AppL10n.tr(
            AppTranslationKeys.columnIndex,
            params: <String, String>{'index': (i + _oneInt).toString()},
          ),
        );
      } else {
        meaningfulHeaders.add(header);
      }
    }

    headers = meaningfulHeaders;
    final List<List<String>> dataRows = worksheetData.skip(headerRowIndex + _oneInt).toList();

    if (dataRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.tr(AppTranslationKeys.xlsxFileContainsNoDataRows))),
      );
      return;
    }

    final List<List<String>> previewRows = dataRows.length > _previewRowLimit
        ? dataRows.sublist(_zeroInt, _previewRowLimit)
        : dataRows;

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
          SnackBar(content: Text(AppL10n.tr(AppTranslationKeys.noValidEntriesFoundInXlsxToImport))),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.tr(AppTranslationKeys.xlsxImportCancelled))),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppL10n.tr(AppTranslationKeys.errorImportingXlsxError, params: <String, String>{'error': e.toString()}),
        ),
      ),
    );
  }
}

/// Loads XLSX data from headers, rows, and column mapping into ImportData.
ImportData loadXLSX(
  List<String> headers,
  List<List<String>> dataRows,
  Map<String, String> columnMapping,
) {
  final ImportData importData = ImportData();
  importData.fileType = SharedStrings.fileTypeXlsx;

  final String dateColumnName = columnMapping['date']!;
  final String descriptionColumnName = columnMapping['description']!;
  final String amountColumnName = columnMapping['amount']!;

  final int dateIndex = headers.indexOf(dateColumnName);
  final int descriptionIndex = headers.indexOf(descriptionColumnName);
  final int amountIndex = headers.indexOf(amountColumnName);

  if (dateIndex == _unsetIndex || descriptionIndex == _unsetIndex || amountIndex == _unsetIndex) {
    AppLogger.warning(
      module: 'xlsx_import_view',
      operation: 'loadXLSX',
      message: 'Column mapping failed - could not find required columns',
      context: <String, Object?>{'columnMapping': columnMapping, 'headers': headers},
    );
    return importData;
  }

  for (int i = _zeroInt; i < dataRows.length; i++) {
    final List<String> row = dataRows[i];

    final int maxIndex = <int>[dateIndex, descriptionIndex, amountIndex].reduce((int a, int b) => a > b ? a : b);
    if (row.length <= maxIndex) {
      continue;
    }

    // Extract values for this row
    final String rawDate = row[dateIndex].trim();
    final String rawDescription = row[descriptionIndex].trim();
    final String rawAmount = row[amountIndex].trim();

    DateTime? date;
    try {
      date = parseFlexibleDate(rawDate);
      if (date == null) {
        throw const FormatException('Could not parse date');
      }
    } catch (_) {
      continue;
    }

    if (rawDescription.isEmpty) {
      continue;
    }

    double? amount;
    try {
      final String amountStr = rawAmount.replaceAll(',', ''); // Handle common number formats
      amount = double.tryParse(amountStr);
      if (amount == null) {
        continue;
      }
    } catch (_) {
      continue;
    }

    importData.entries.add(
      ImportEntry(
        date: date,
        name: rawDescription,
        amount: amount,
        type: SharedStrings.importTypeXlsx,
        fitid: 'xlsx_row_${i + _oneInt}_${date.millisecondsSinceEpoch}',
        memo: '',
        number: '',
        stockAction: '',
        stockSymbol: '',
        stockQuantity: _zeroDouble,
        stockPrice: _zeroDouble,
        stockCommission: _zeroDouble,
      ),
    );
  }

  return importData;
}

/// Parses dates in multiple common formats:
/// - ISO format: YYYY-MM-DD (2023-01-01)
/// - European format: DD/MM/YYYY (30/06/2025)
/// - US format: MM/DD/YYYY (06/30/2025)
/// - Short year formats: DD/MM/YY (30/06/25)
DateTime? parseFlexibleDate(String dateStr) {
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
    final int day = int.parse(euroMatch.group(_oneInt)!);
    final int month = int.parse(euroMatch.group(_twoInt)!);
    final int yearStr = int.parse(euroMatch.group(_threeInt)!);

    // Handle 2-digit years
    final int year = yearStr < _twoDigitYearMax
        ? (yearStr < _twoDigitYearPivot ? _yearBaseRecent + yearStr : _yearBasePast + yearStr)
        : yearStr;

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
    final int month = int.parse(usMatch.group(_oneInt)!);
    final int day = int.parse(usMatch.group(_twoInt)!);
    final int yearStr = int.parse(usMatch.group(_threeInt)!);

    // Handle 2-digit years
    final int year = yearStr < _twoDigitYearMax
        ? (yearStr < _twoDigitYearPivot ? _yearBaseRecent + yearStr : _yearBasePast + yearStr)
        : yearStr;

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
    final int year = int.parse(ymdMatch.group(_oneInt)!);
    final int month = int.parse(ymdMatch.group(_twoInt)!);
    final int day = int.parse(ymdMatch.group(_threeInt)!);

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
