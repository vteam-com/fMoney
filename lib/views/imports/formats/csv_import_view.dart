// ignore_for_file: always_put_control_body_on_new_line

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/views/imports/shared/data_import_view.dart';
import 'package:money/widgets/dialogs/csv_column_mapper_dialog.dart'; // Import the dialog

const int _previewRowLimit = 5;
const String _skipReasonMissingMappedColumns = 'missingMappedColumns';
const String _skipReasonInsufficientColumns = 'insufficientColumns';
const String _skipReasonInvalidDate = 'invalidDate';
const String _skipReasonEmptyDescription = 'emptyDescription';
const String _skipReasonInvalidAmount = 'invalidAmount';
const String _skipReasonMissingRequiredMapping = 'missingRequiredMapping';
const String _noDescriptionPlaceholder = 'no description';
const String _actionDescriptionSeparator = ' | ';
const int _nearbyActionPrimaryOffset = 2;
const int _nearbyActionSecondaryOffset = 1;
const List<String> _fallbackActionHeaderAliases = <String>[
  'action',
  'activity',
  'details',
  'transaction',
  'transaction details',
  'narrative',
  'memo',
];

/// Represents parsed CSV headers and data rows.
class CsvRowsData {
  /// Creates parsed CSV rows data.
  CsvRowsData({
    required this.headers,
    required this.dataRows,
  });

  /// Header columns from the first CSV row.
  final List<String> headers;

  /// Data rows from the remaining CSV rows.
  final List<List<String>> dataRows;
}

/// Imports CSV file and parses transaction data from comma-separated format.
Future<void> importCSV(BuildContext context, String filePath) async {
  try {
    final File file = File(filePath);
    final String csvContent = await file.readAsString();

    if (!context.mounted) return; // Guard after await

    if (csvContent.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.tr(AppTranslationKeys.csvFileEmpty))),
      );
      return;
    }

    final CsvRowsData csvRowsData = parseCsvContent(csvContent);
    final List<String> headers = csvRowsData.headers;
    final List<List<String>> dataRows = csvRowsData.dataRows;
    final List<List<String>> previewRows = dataRows.length > _previewRowLimit
        ? dataRows.sublist(0, _previewRowLimit)
        : dataRows;

    if (!context.mounted) {
      return;
    }

    final Map<String, String>? columnMapping = await showCsvColumnMapperDialog(
      context: context,
      headers: headers,
      dataRows: previewRows,
    );

    if (!context.mounted) {
      return;
    } // Guard after await

    if (columnMapping != null) {
      final ImportData importData = loadCSV(headers, dataRows, columnMapping);

      if (importData.entries.isNotEmpty) {
        if (importData.diagnostics.skippedRows > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppL10n.tr(
                  AppTranslationKeys.csvImportRowsImportedAndSkipped,
                  params: <String, String>{
                    'imported': importData.entries.length.toString(),
                    'skipped': importData.diagnostics.skippedRows.toString(),
                  },
                ),
              ),
            ),
          );
        }
        showAndConfirmTransactionToImport(context, importData);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppL10n.tr(AppTranslationKeys.noValidEntriesFoundInCsvToImport))),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.tr(AppTranslationKeys.csvImportCancelled))),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppL10n.tr(AppTranslationKeys.errorImportingCsvError, params: <String, String>{'error': e.toString()}),
          ),
        ),
      );
    }
  }
}

/// Parses CSV [csvContent] into headers and data rows using RFC-compatible CSV rules.
CsvRowsData parseCsvContent(String csvContent) {
  final List<List<dynamic>> parsedRows = const CsvDecoder(
    dynamicTyping: false,
  ).convert(csvContent);
  if (parsedRows.isEmpty) {
    return CsvRowsData(headers: <String>[], dataRows: <List<String>>[]);
  }

  final List<String> headers = _rowToTrimmedStringList(parsedRows.first);
  if (headers.isNotEmpty) {
    headers[0] = headers[0].replaceFirst('\ufeff', '');
  }
  final List<List<String>> dataRows = parsedRows.skip(1).map(_rowToTrimmedStringList).toList();
  return CsvRowsData(headers: headers, dataRows: dataRows);
}

/// Converts dynamic CSV row values into a trimmed string list.
List<String> _rowToTrimmedStringList(List<dynamic> row) {
  return row
      .map(
        (dynamic cell) => cell == null ? '' : cell.toString().trim(),
      )
      .toList();
}

/// Returns a case-insensitive header index or -1 if the header is absent.
int _indexOfHeaderIgnoreCase(List<String> headers, String targetHeader) {
  for (int i = 0; i < headers.length; i++) {
    if (headers[i].trim().toLowerCase() == targetHeader.toLowerCase()) {
      return i;
    }
  }
  return -1;
}

/// Returns the first matching index among common action-like header aliases.
int _findActionHeaderIndex(List<String> headers) {
  for (final String alias in _fallbackActionHeaderAliases) {
    final int index = _indexOfHeaderIgnoreCase(headers, alias);
    if (index >= 0) {
      return index;
    }
  }
  return -1;
}

/// Normalizes a description-like value for robust placeholder matching.
String _normalizeForPlaceholderCheck(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

/// Returns true when [descriptionValue] is considered a non-informative placeholder.
bool _isDescriptionPlaceholder(String descriptionValue) {
  final String normalized = _normalizeForPlaceholderCheck(descriptionValue);
  if (normalized.isEmpty) {
    return true;
  }
  return normalized == _noDescriptionPlaceholder;
}

/// Returns true when [candidate] can be used as an Action fallback for [descriptionValue].
bool _isValidActionCandidate(String candidate, String descriptionValue) {
  final String trimmed = candidate.trim();
  if (trimmed.isEmpty) {
    return false;
  }

  final String normalizedCandidate = _normalizeForPlaceholderCheck(trimmed);
  if (normalizedCandidate.isEmpty || normalizedCandidate == _noDescriptionPlaceholder) {
    return false;
  }

  final String normalizedDescription = _normalizeForPlaceholderCheck(descriptionValue);
  return normalizedCandidate != normalizedDescription;
}

/// Returns true when [headerValue] semantically represents action/details text.
bool _isActionLikeHeader(String headerValue) {
  final String normalizedHeader = _normalizeForPlaceholderCheck(headerValue);
  for (final String headerAlias in _fallbackActionHeaderAliases) {
    final String normalizedAlias = _normalizeForPlaceholderCheck(headerAlias);
    if (normalizedHeader.contains(normalizedAlias)) {
      return true;
    }
  }
  return false;
}

/// Resolves Action text from known headers or nearby columns for placeholder descriptions.
String _resolveActionValue({
  required List<String> headers,
  required List<String> row,
  required int actionIndex,
  required int descriptionIndex,
  required String descriptionValue,
}) {
  final bool placeholderDescription = _isDescriptionPlaceholder(descriptionValue);

  if (actionIndex >= 0 && actionIndex < row.length) {
    final String actionFromHeader = row[actionIndex].trim();
    if (_isValidActionCandidate(actionFromHeader, descriptionValue)) {
      return actionFromHeader;
    }
  }

  // Only use positional heuristics when description is clearly a placeholder.
  if (!placeholderDescription) {
    return '';
  }

  final List<int> nearbyCandidateIndices = <int>[
    descriptionIndex - _nearbyActionPrimaryOffset,
    descriptionIndex - _nearbyActionSecondaryOffset,
  ];
  for (final int index in nearbyCandidateIndices) {
    if (index < 0 || index >= row.length) {
      continue;
    }
    if (index >= headers.length || !_isActionLikeHeader(headers[index])) {
      continue;
    }
    final String candidate = row[index].trim();
    if (_isValidActionCandidate(candidate, descriptionValue)) {
      return candidate;
    }
  }

  for (int i = 0; i < headers.length && i < row.length; i++) {
    if (!_isActionLikeHeader(headers[i])) {
      continue;
    }

    final String candidate = row[i].trim();
    if (_isValidActionCandidate(candidate, descriptionValue)) {
      return candidate;
    }
  }

  return '';
}

/// Builds the final import description from [descriptionValue] and [actionValue].
///
/// Rules:
/// - If [descriptionValue] is empty/placeholder, use [actionValue].
/// - If [actionValue] is empty, use [descriptionValue].
/// - If [actionValue] already contains [descriptionValue], use [actionValue].
/// - Otherwise combine both values for better traceability.
String _resolveDescription(String descriptionValue, String actionValue) {
  final String trimmedAction = actionValue.trim();
  final String trimmedDescription = descriptionValue.trim();

  if (_isDescriptionPlaceholder(trimmedDescription)) {
    return trimmedAction;
  }

  if (trimmedAction.isEmpty) {
    return trimmedDescription;
  }

  final String actionLower = trimmedAction.toLowerCase();
  final String descriptionLower = trimmedDescription.toLowerCase();
  if (actionLower.contains(descriptionLower)) {
    return trimmedAction;
  }

  return '$trimmedAction$_actionDescriptionSeparator$trimmedDescription';
}

/// Loads CSV data from headers, rows, and column mapping into ImportData.
ImportData loadCSV(
  List<String> headers,
  List<List<String>> dataRows,
  Map<String, String> columnMapping,
) {
  final ImportData importData = ImportData();
  importData.fileType = SharedStrings.fileTypeCsv;
  importData.diagnostics.processedRows = dataRows.length;

  final String? dateColumnName = columnMapping['date'];
  final String? descriptionColumnName = columnMapping['description'];
  final String? amountColumnName = columnMapping['amount'];
  if (dateColumnName == null || descriptionColumnName == null || amountColumnName == null) {
    importData.diagnostics.incrementSkipped(_skipReasonMissingRequiredMapping);
    return importData;
  }

  final int dateIndex = headers.indexOf(dateColumnName);
  final int descriptionIndex = headers.indexOf(descriptionColumnName);
  final int amountIndex = headers.indexOf(amountColumnName);
  final int actionIndex = _findActionHeaderIndex(headers);

  if (dateIndex == -1 || descriptionIndex == -1 || amountIndex == -1) {
    importData.diagnostics.incrementSkipped(_skipReasonMissingMappedColumns);
    return importData;
  }

  // Optional fields for investment/stock transactions
  final String? quantityColumnName = columnMapping['quantity'];
  final String? priceColumnName = columnMapping['price'];
  final int quantityIndex = quantityColumnName != null ? headers.indexOf(quantityColumnName) : -1;
  final int priceIndex = priceColumnName != null ? headers.indexOf(priceColumnName) : -1;

  for (int i = 0; i < dataRows.length; i++) {
    final List<String> row = dataRows[i];

    final List<int> requiredIndices = <int>[dateIndex, descriptionIndex, amountIndex];
    if (quantityIndex >= 0) {
      requiredIndices.add(quantityIndex);
    }
    if (priceIndex >= 0) {
      requiredIndices.add(priceIndex);
    }

    final int maxIndex = requiredIndices.reduce((int a, int b) => a > b ? a : b);
    if (row.length <= maxIndex) {
      importData.diagnostics.incrementSkipped(_skipReasonInsufficientColumns);
      continue;
    }

    DateTime? date;
    try {
      date = DateTime.parse(row[dateIndex].trim());
    } catch (_) {
      importData.diagnostics.incrementSkipped(_skipReasonInvalidDate);
      continue;
    }

    final String actionValue = _resolveActionValue(
      headers: headers,
      row: row,
      actionIndex: actionIndex,
      descriptionIndex: descriptionIndex,
      descriptionValue: row[descriptionIndex],
    );
    final String description = _resolveDescription(row[descriptionIndex], actionValue);
    if (description.isEmpty) {
      importData.diagnostics.incrementSkipped(_skipReasonEmptyDescription);
      continue;
    }

    double? amount;
    try {
      amount = double.tryParse(row[amountIndex].trim());
      if (amount == null) {
        importData.diagnostics.incrementSkipped(_skipReasonInvalidAmount);
        continue;
      }
    } catch (_) {
      importData.diagnostics.incrementSkipped(_skipReasonInvalidAmount);
      continue;
    }

    // Parse optional quantity and price fields
    double stockQuantity = 0.0;
    double stockPrice = 0.0;

    if (quantityIndex >= 0 && quantityIndex < row.length) {
      try {
        final String quantityStr = row[quantityIndex].trim();
        if (quantityStr.isNotEmpty) {
          stockQuantity = double.tryParse(quantityStr) ?? 0.0;
        }
      } catch (_) {
        // Ignore parse errors for optional fields
      }
    }

    if (priceIndex >= 0 && priceIndex < row.length) {
      try {
        final String priceStr = row[priceIndex].trim();
        if (priceStr.isNotEmpty) {
          stockPrice = double.tryParse(priceStr) ?? 0.0;
        }
      } catch (_) {
        // Ignore parse errors for optional fields
      }
    }

    importData.entries.add(
      ImportEntry(
        date: date,
        name: description,
        amount: amount,
        type: SharedStrings.importTypeCsv,
        fitid: 'csv_row_${i + 1}_${date.millisecondsSinceEpoch}',
        memo: actionValue,
        number: '',
        stockAction: '',
        stockSymbol: '',
        stockQuantity: stockQuantity,
        stockPrice: stockPrice,
        stockCommission: 0.0,
      ),
    );
  }
  return importData;
}
