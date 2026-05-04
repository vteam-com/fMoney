// ignore_for_file: always_put_control_body_on_new_line

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/views/imports/formats/csv_import_view.dart';
import 'package:money/views/imports/shared/data_import_view.dart';

const String _investmentHeaderRunDate = 'Run Date';
const String _investmentHeaderAccount = 'Account';
const String _investmentHeaderAccountNumber = 'Account Number';
const String _investmentHeaderAction = 'Action';
const String _investmentHeaderSymbol = 'Symbol';
const String _investmentHeaderDescription = 'Description';
const String _investmentHeaderQuantity = 'Quantity';
const String _investmentHeaderPrice = 'Price';
const String _investmentHeaderAmount = 'Amount';
const String _investmentHeaderCommission = 'Commission';

const int _datePartCount = 3;
const int _datePartIndexYear = 2;

const String _skipReasonInvalidDate = 'invalidDate';
const String _skipReasonEmptyDescription = 'emptyDescription';
const String _skipReasonInvalidAmount = 'invalidAmount';
const String _skipReasonMissingRequiredColumns = 'missingRequiredColumns';

/// Checks if CSV appears to be an investment CSV export by examining headers.
bool isInvestmentCSV(final List<String> headers) {
  final Set<String> headerSet = <String>{
    for (final String header in headers) header.trim(),
  };

  // Baseline support: broker exports following the Fidelity-style investment schema.
  return headerSet.contains(_investmentHeaderRunDate) &&
      headerSet.contains(_investmentHeaderAccountNumber) &&
      headerSet.contains(_investmentHeaderAmount);
}

/// Imports investment CSV files and maps standard investment transaction fields.
Future<void> importInvestmentCSV(final BuildContext context, final String filePath) async {
  try {
    final File file = File(filePath);
    final String csvContent = await file.readAsString();

    if (!context.mounted) return;

    if (csvContent.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppL10n.tr(AppTranslationKeys.csvFileEmpty))),
      );
      return;
    }

    // Parse CSV content
    final CsvRowsData csvRowsData = parseCsvContent(csvContent);
    final List<String> headers = csvRowsData.headers;
    final List<List<String>> dataRows = csvRowsData.dataRows;

    if (!context.mounted) {
      return;
    }

    // Verify supported investment CSV format
    if (!isInvestmentCSV(headers)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppL10n.tr(AppTranslationKeys.noValidEntriesFoundInCsvToImport)),
        ),
      );
      return;
    }

    // Load and process investment CSV
    final ImportData importData = loadInvestmentCSV(headers, dataRows);

    if (!context.mounted) {
      return;
    }

    if (importData.entries.isNotEmpty) {
      showAndConfirmTransactionToImport(context, importData);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppL10n.tr(AppTranslationKeys.noValidEntriesFoundInCsvToImport))),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppL10n.tr(
              AppTranslationKeys.errorImportingCsvError,
              params: <String, String>{
                'error': e.toString(),
              },
            ),
          ),
        ),
      );
    }
  }
}

/// Parses investment dates supporting both ISO and common broker formats.
DateTime? _parseInvestmentDate(final String rawValue) {
  final String trimmed = rawValue.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final DateTime? isoParsed = DateTime.tryParse(trimmed);
  if (isoParsed != null) {
    return isoParsed;
  }

  final List<String> parts = trimmed.split('/');
  if (parts.length == _datePartCount) {
    final int? month = int.tryParse(parts[0]);
    final int? day = int.tryParse(parts[1]);
    final int? year = int.tryParse(parts[_datePartIndexYear]);
    if (month != null && day != null && year != null) {
      return DateTime(year, month, day);
    }
  }

  return null;
}

/// Parses investment amounts supporting symbols, commas, and parentheses negatives.
double? _parseInvestmentAmount(final String rawValue) {
  final String trimmed = rawValue.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final bool isParenthesisNegative = trimmed.startsWith('(') && trimmed.endsWith(')');
  String normalized = trimmed.replaceAll(r'$', '').replaceAll(',', '').replaceAll('(', '').replaceAll(')', '');

  if (normalized.startsWith('+')) {
    normalized = normalized.substring(1);
  }

  final double? parsed = double.tryParse(normalized);
  if (parsed == null) {
    return null;
  }
  return isParenthesisNegative ? -parsed : parsed;
}

/// Loads investment CSV data and creates import entries.
ImportData loadInvestmentCSV(
  final List<String> headers,
  final List<List<String>> dataRows,
) {
  final ImportData importData = ImportData();
  importData.fileType = SharedStrings.fileTypeCsv;
  importData.diagnostics.processedRows = dataRows.length;

  // Find column indices
  final int runDateIndex = headers.indexOf(_investmentHeaderRunDate);
  final int accountIndex = headers.indexOf(_investmentHeaderAccount);
  final int accountNumberIndex = headers.indexOf(_investmentHeaderAccountNumber);
  final int actionIndex = headers.indexOf(_investmentHeaderAction);
  final int descriptionIndex = headers.indexOf(_investmentHeaderDescription);
  final int amountIndex = headers.indexOf(_investmentHeaderAmount);
  final int symbolIndex = headers.indexOf(_investmentHeaderSymbol);
  final int quantityIndex = headers.indexOf(_investmentHeaderQuantity);
  final int priceIndex = headers.indexOf(_investmentHeaderPrice);
  final int commissionIndex = headers.indexOf(_investmentHeaderCommission);

  // Verify required columns exist
  if (runDateIndex == -1 ||
      accountIndex == -1 ||
      accountNumberIndex == -1 ||
      descriptionIndex == -1 ||
      amountIndex == -1) {
    importData.diagnostics.incrementSkipped(_skipReasonMissingRequiredColumns);
    return importData;
  }

  for (int i = 0; i < dataRows.length; i++) {
    final List<String> row = dataRows[i];

    // Verify row has enough columns
    final int maxIndex = <int>[
      runDateIndex,
      accountIndex,
      accountNumberIndex,
      descriptionIndex,
      amountIndex,
    ].reduce((final int a, final int b) => a > b ? a : b);

    if (row.length <= maxIndex) {
      importData.diagnostics.incrementSkipped(_skipReasonMissingRequiredColumns);
      continue;
    }

    // Parse date
    final DateTime? date = _parseInvestmentDate(row[runDateIndex]);
    if (date == null) {
      importData.diagnostics.incrementSkipped(_skipReasonInvalidDate);
      continue;
    }

    // Parse description
    final String description = row[descriptionIndex].trim();
    if (description.isEmpty) {
      importData.diagnostics.incrementSkipped(_skipReasonEmptyDescription);
      continue;
    }

    // Parse amount
    final double? amount = _parseInvestmentAmount(row[amountIndex]);
    if (amount == null) {
      importData.diagnostics.incrementSkipped(_skipReasonInvalidAmount);
      continue;
    }

    // Parse investment fields if present
    String stockAction = '';
    String stockSymbol = '';
    double stockQuantity = 0.0;
    double stockPrice = 0.0;
    double stockCommission = 0.0;

    if (symbolIndex != -1 && row.length > symbolIndex) {
      stockSymbol = row[symbolIndex].trim();
    }

    if (actionIndex != -1 && row.length > actionIndex) {
      stockAction = row[actionIndex].trim();
    }

    if (quantityIndex != -1 && row.length > quantityIndex) {
      try {
        final String qtyStr = row[quantityIndex].trim();
        if (qtyStr.isNotEmpty) {
          stockQuantity = double.parse(qtyStr);
        }
      } catch (_) {
        // Ignore parse errors
      }
    }

    if (priceIndex != -1 && row.length > priceIndex) {
      try {
        final String priceStr = row[priceIndex].trim();
        if (priceStr.isNotEmpty) {
          stockPrice = double.parse(priceStr);
        }
      } catch (_) {
        // Ignore parse errors
      }
    }

    if (commissionIndex != -1 && row.length > commissionIndex) {
      try {
        final String commStr = row[commissionIndex].trim();
        if (commStr.isNotEmpty) {
          stockCommission = double.parse(commStr);
        }
      } catch (_) {
        // Ignore parse errors
      }
    }

    // Create entry
    final ImportEntry entry = ImportEntry(
      type: 'investment_csv',
      date: date,
      amount: amount,
      name: description,
      fitid: 'investment_csv_${date.millisecondsSinceEpoch}_$i',
      memo: description,
      number: '',
      stockAction: stockAction,
      stockSymbol: stockSymbol,
      stockQuantity: stockQuantity,
      stockPrice: stockPrice,
      stockCommission: stockCommission,
    );

    importData.entries.add(entry);
  }

  return importData;
}
