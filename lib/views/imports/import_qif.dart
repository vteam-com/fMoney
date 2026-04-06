import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/views/imports/import_data.dart';
import 'package:money/widgets/pure/snack_bar.dart';

const int _minFieldLength = 2;

///
/// schema https://www.w3.org/2000/10/swap/pim/qif-doc/QIF-doc.htm
///
void importQIF(final BuildContext context, final String filePath) {
  final File file = File(filePath);

  file
      .readAsLines()
      .then((final List<String> lines) {
        final ImportData importData = loadQIF(lines);
        importData.fileType = SharedStrings.fileTypeQif;
        if (context.mounted) {
          showAndConfirmTransactionToImport(context, importData);
        }
      })
      .catchError((final dynamic e) {
        logger.e('Error reading file: $e');
        SnackBarService.displayError(message: e.toString(), autoDismiss: false);
      });
}

/// Loads QIF data from lines and returns ImportData with parsed entries.
ImportData loadQIF(final List<String> lines) {
  final ImportData importData = ImportData();

  ImportEntry currentEntry = ImportEntry.blank();

  for (final String line in lines) {
    if (line == '^') {
      // Indicates the end of a transaction
      // add this entry
      importData.entries.add(currentEntry);
      // started new transaction object
      currentEntry = ImportEntry.blank();
      continue;
    }
    if (line.length >= _minFieldLength) {
      final String fieldLetter = line[0];
      final String fieldData = line.substring(1);
      switch (fieldLetter) {
        case '!':
          switch (fieldData) {
            case SharedStrings.qifTypeInvestment:
              importData.accountType = AccountType.investment;
          }

        case SharedStrings.qifFieldDate:
          // In some cases the QIF will
          // have the date in the following format 01/30'2000
          // so before processing the date we replace the "'" with "/"
          String dateAsString = getNormalizedValue(fieldData);
          dateAsString = dateAsString.replaceAll("'", '/');
          currentEntry.date = DateFormat('MM/dd/yyyy').parse(dateAsString);

        case SharedStrings.qifFieldAmount:
        case SharedStrings.qifFieldAmountAlt:
          // Amount
          currentEntry.amount = parseUSDAmount(fieldData) ?? 0.00;

        case SharedStrings.qifFieldMemo:
          // Memo
          currentEntry.name = getNormalizedValue(fieldData);

        case SharedStrings.qifFieldAction:
          // Stock Action
          currentEntry.stockAction = getNormalizedValue(fieldData);

        case SharedStrings.qifFieldQuantity:
          // Quantity - We use Amount parser because quantity can have fraction
          currentEntry.stockQuantity = parseUSDAmount(fieldData) ?? 0.0;

        case SharedStrings.qifFieldSecurity:
          // Security
          currentEntry.stockSymbol = getNormalizedValue(fieldData);

        case SharedStrings.qifFieldPayee:
        case SharedStrings.qifFieldPrice:
          currentEntry.stockPrice = parseUSDAmount(fieldData) ?? 0.00;
      }
    }
  }

  return importData;
}
