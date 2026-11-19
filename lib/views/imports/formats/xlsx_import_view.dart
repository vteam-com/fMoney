// ignore_for_file: always_put_control_body_on_new_line

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/views/imports/formats/csv_import_view.dart';
import 'package:money/views/imports/shared/data_import_view.dart';
import 'package:money/widgets/dialogs/csv_column_mapper_dialog.dart';
import 'package:money/widgets/dialogs/xlsx_header_row_selector_dialog.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';

const int _zeroInt = 0;
const int _oneInt = 1;
const int _twoInt = 2;
const int _unsetIndex = -1;
const int _headerPreviewCount = 10;
const int _previewRowLimit = 5;
const int _datePadWidth = 2;
const String _datePadChar = '0';
const int _excelDateMin = 20000;
const int _excelDateMax = 60000;
const int _excelBaseYear = 1899;
const int _excelBaseMonth = 12;
const int _excelBaseDay = 30;
const int _alphabetLength = 26;
const int _letterACodeUnit = 0x41;

// Simple, dependency-free XLSX parser (only one sheet, static values)
/// Imports XLSX file and parses transaction data from Excel format.
Future<void> importXLSX(BuildContext context, String filePath) async {
  try {
    final File file = File(filePath);
    final Uint8List bytes = await file.readAsBytes();
    if (!context.mounted) return;
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
      sharedStrings = parseXlsxSharedStrings(xml);
    }

    // Extract first sheet*.xml
    final ArchiveFile sheetFile = archive.files.firstWhere(
      (ArchiveFile file) => RegExp(r'^xl/worksheets/sheet.*\.xml$').hasMatch(file.name),
      orElse: () => ArchiveFile('', _zeroInt, <int>[]),
    );

    if (sheetFile.name.isEmpty) {
      SnackBarService.displayError(message: AppL10n.tr(AppTranslationKeys.noSheetXmlFoundInXlsxFile));
      return;
    }

    final String sheetXml = utf8.decode(sheetFile.content, allowMalformed: true);
    final List<List<String>> worksheetData = parseXlsxSheetRows(sheetXml, sharedStrings);

    // Filter out completely empty rows, but keep rows that might be headers
    final List<List<String>> filteredData = worksheetData
        .where((List<String> row) => row.isNotEmpty && row.any((String cell) => cell.trim().isNotEmpty))
        .toList();

    if (filteredData.isEmpty) {
      SnackBarService.displayWarning(message: AppL10n.tr(AppTranslationKeys.xlsxFileContainsNoValidData));
      return;
    }

    worksheetData.clear();
    worksheetData.addAll(filteredData);

    if (worksheetData.isEmpty) {
      SnackBarService.displayWarning(message: AppL10n.tr(AppTranslationKeys.xlsxFileContainsNoDataRows));
      return;
    }

    // Prompt user to select the header row
    final int? headerRowIndex = await showXlsxHeaderRowSelectorDialog(
      context: context,
      rows: worksheetData.length > _headerPreviewCount
          ? worksheetData.sublist(_zeroInt, _headerPreviewCount)
          : worksheetData,
    );
    if (!context.mounted) return;
    if (headerRowIndex == null) {
      SnackBarService.displayInfo(message: AppL10n.tr(AppTranslationKeys.xlsxImportCancelled));
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
      SnackBarService.displayWarning(message: AppL10n.tr(AppTranslationKeys.xlsxFileContainsNoDataRows));
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
    if (!context.mounted) return;

    if (columnMapping != null) {
      final ImportData importData = loadXLSX(headers, dataRows, columnMapping);
      if (importData.entries.isNotEmpty) {
        showImportSkippedRowsWarning(importData);
        showAndConfirmTransactionToImport(context, importData);
      } else {
        SnackBarService.displayWarning(message: AppL10n.tr(AppTranslationKeys.noValidEntriesFoundInXlsxToImport));
      }
    } else {
      SnackBarService.displayInfo(message: AppL10n.tr(AppTranslationKeys.xlsxImportCancelled));
    }
  } catch (e) {
    SnackBarService.displayError(
      message: AppL10n.tr(AppTranslationKeys.errorImportingXlsxError, params: <String, String>{'error': e.toString()}),
    );
  }
}

/// Loads XLSX data from headers, rows, and column mapping into ImportData.
///
/// Rows go through the CSV loader (same quantity/price mapping and skip diagnostics);
/// Excel serial dates are converted to ISO dates in the mapped date column only.
ImportData loadXLSX(
  List<String> headers,
  List<List<String>> dataRows,
  Map<String, String> columnMapping,
) {
  final String? dateColumn = columnMapping['date'];
  final int dateIndex = dateColumn == null ? _unsetIndex : indexOfMappedColumn(headers, dateColumn);
  final List<List<String>> rows = dataRows.map((List<String> row) {
    if (dateIndex < _zeroInt || dateIndex >= row.length) {
      return row;
    }
    final List<String> converted = List<String>.of(row);
    converted[dateIndex] = excelSerialDateToIso(row[dateIndex]);
    return converted;
  }).toList();

  final ImportData importData = loadCSV(headers, rows, columnMapping);
  importData.fileType = SharedStrings.fileTypeXlsx;
  for (final ImportEntry entry in importData.entries) {
    entry.type = SharedStrings.importTypeXlsx;
  }
  return importData;
}

/// Converts an Excel serial date such as `45306` to `2024-01-15`; other text is returned unchanged.
String excelSerialDateToIso(String value) {
  final double? excelDate = double.tryParse(value.trim());
  if (excelDate == null || excelDate <= _excelDateMin || excelDate >= _excelDateMax) {
    return value;
  }
  // Excel's day 1 = 1900-01-01 (Excel bug means 1900-02-29 exists)
  final DateTime baseDate = DateTime(_excelBaseYear, _excelBaseMonth, _excelBaseDay);
  final DateTime convertedDate = baseDate.add(Duration(days: excelDate.floor()));
  return '${convertedDate.year}-${convertedDate.month.toString().padLeft(_datePadWidth, _datePadChar)}-${convertedDate.day.toString().padLeft(_datePadWidth, _datePadChar)}';
}

/// Returns the text of each `<si>` entry of an XLSX sharedStrings.xml, joining rich-text runs.
List<String> parseXlsxSharedStrings(String xml) {
  final RegExp itemRegex = RegExp(r'<(?:\w+:)?si(?:\s[^>]*)?>(.*?)</(?:\w+:)?si>', dotAll: true);
  final RegExp textRegex = RegExp(r'<(?:\w+:)?t(?:\s[^>]*)?>(.*?)</(?:\w+:)?t>', dotAll: true);
  return itemRegex.allMatches(xml).map((RegExpMatch item) {
    final String text = textRegex
        .allMatches(item.group(_oneInt) ?? '')
        .map((RegExpMatch m) => m.group(_oneInt) ?? '')
        .join();
    return _decodeXmlEntities(text.replaceAll('\r', '').replaceAll('\n', '')).trim();
  }).toList();
}

/// Parses the rows of an XLSX worksheet into cell texts, placing each cell at
/// the column given by its `r` reference (for example `C5`) so empty cells keep
/// their position. Values of `t="s"` cells are looked up in [sharedStrings].
List<List<String>> parseXlsxSheetRows(String sheetXml, List<String> sharedStrings) {
  final RegExp rowRegex = RegExp(r'<(?:\w+:)?row(?:\s[^>]*)?>(.*?)</(?:\w+:)?row>', dotAll: true);
  final RegExp cellRegex = RegExp(r'<(?:\w+:)?c(\s[^>]*?)?(?:/>|>(.*?)</(?:\w+:)?c>)', dotAll: true);
  final RegExp referenceRegex = RegExp(r'\br="([A-Za-z]+)\d*"');
  final RegExp typeRegex = RegExp(r'\bt="([^"]*)"');
  final RegExp valueRegex = RegExp(r'<(?:\w+:)?v(?:\s[^>]*)?>(.*?)</(?:\w+:)?v>', dotAll: true);
  final RegExp inlineRegex = RegExp(
    r'<(?:\w+:)?is(?:\s[^>]*)?>.*?<(?:\w+:)?t(?:\s[^>]*)?>(.*?)</(?:\w+:)?t>.*?</(?:\w+:)?is>',
    dotAll: true,
  );

  final List<List<String>> rows = <List<String>>[];
  for (final RegExpMatch rowMatch in rowRegex.allMatches(sheetXml)) {
    final List<String> rowData = <String>[];
    for (final RegExpMatch cellMatch in cellRegex.allMatches(rowMatch.group(_oneInt) ?? '')) {
      final String attributes = cellMatch.group(_oneInt) ?? '';
      final String cellXml = cellMatch.group(_twoInt) ?? '';
      final String? cellType = typeRegex.firstMatch(attributes)?.group(_oneInt);

      String value = '';
      final RegExpMatch? vMatch = valueRegex.firstMatch(cellXml);
      if (vMatch != null) {
        value = vMatch.group(_oneInt)?.trim() ?? '';
        if (cellType == 's') {
          final int? sharedIndex = int.tryParse(value);
          value = sharedIndex != null && sharedIndex >= _zeroInt && sharedIndex < sharedStrings.length
              ? sharedStrings[sharedIndex]
              : '';
        } else {
          value = _decodeXmlEntities(value);
        }
      } else {
        // Handle inline strings: <is><t>Text</t></is>
        value = _decodeXmlEntities(inlineRegex.firstMatch(cellXml)?.group(_oneInt)?.trim() ?? '');
      }

      final String? reference = referenceRegex.firstMatch(attributes)?.group(_oneInt);
      final int columnIndex = reference == null ? rowData.length : xlsxColumnLettersToIndex(reference);
      while (rowData.length <= columnIndex) {
        rowData.add('');
      }
      rowData[columnIndex] = value;
    }
    rows.add(rowData);
  }
  return rows;
}

/// Converts XLSX column letters to a zero-based index (`A` is 0, `Z` is 25, `AA` is 26).
int xlsxColumnLettersToIndex(String letters) {
  int index = _zeroInt;
  for (final int codeUnit in letters.toUpperCase().codeUnits) {
    index = index * _alphabetLength + (codeUnit - _letterACodeUnit + _oneInt);
  }
  return index - _oneInt;
}

/// Decodes the XML entities and accented characters found in XLSX cell text.
String _decodeXmlEntities(String value) {
  return value
      .replaceAll(SharedStrings.xmlEntityLt, '<')
      .replaceAll(SharedStrings.xmlEntityGt, '>')
      .replaceAll(SharedStrings.xmlEntityQuot, '"')
      .replaceAll(SharedStrings.xmlEntityApos, "'")
      .replaceAll(SharedStrings.xmlEntityCedilla, 'ç')
      .replaceAll(SharedStrings.xmlEntityATilde, 'ã')
      .replaceAll(SharedStrings.xmlEntityEAcute, 'é')
      .replaceAll(SharedStrings.xmlEntityECirc, 'ê')
      .replaceAll(SharedStrings.xmlEntityOTilde, 'õ')
      .replaceAll(SharedStrings.xmlEntityOAcute, 'ó')
      .replaceAll(SharedStrings.xmlEntityAmp, '&');
}
