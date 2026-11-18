import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/views/imports/shared/data_import_view.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';

const int _minFieldLength = 2;
const String _skipReasonInvalidDate = 'invalidDate';

/// QIF header line (after `!`) that starts an account description block.
const String _qifHeaderAccount = 'Account';

/// Field letter holding the account name inside an `!Account` block.
const String _qifAccountFieldName = 'N';

///
/// schema https://www.w3.org/2000/10/swap/pim/qif-doc/QIF-doc.htm
///
Future<void> importQIF(BuildContext context, String filePath) {
  final File file = File(filePath);

  return file
      .readAsLines()
      .then((List<String> lines) {
        final ImportData importData = loadQIF(lines);
        importData.fileType = SharedStrings.fileTypeQif;
        if (context.mounted) {
          showImportSkippedRowsWarning(importData);
          showAndConfirmTransactionToImport(context, importData);
        }
      })
      .catchError((dynamic e) {
        logger.e('Error reading file: $e');
        SnackBarService.displayError(message: e.toString(), autoDismiss: false);
      });
}

/// Loads QIF data from lines and returns ImportData with parsed entries.
///
/// Entries whose date is missing or unreadable are skipped and counted in the diagnostics.
/// Accounts named in `!Account` blocks that hold transactions are recorded in [ImportData.sourceAccounts].
ImportData loadQIF(List<String> lines) {
  final ImportData importData = ImportData();

  ImportEntry currentEntry = ImportEntry.blank();
  bool hasValidDate = false;
  bool inAccountBlock = false;
  String currentAccountName = '';

  for (final String line in lines) {
    if (line == '^') {
      if (inAccountBlock) {
        // End of an account description, not a transaction
        continue;
      }
      // Indicates the end of a transaction
      if (hasValidDate) {
        importData.entries.add(currentEntry);
        if (currentAccountName.isNotEmpty) {
          importData.sourceAccounts.add(currentAccountName);
        }
      } else {
        importData.diagnostics.incrementSkipped(_skipReasonInvalidDate);
      }
      // started new transaction object
      currentEntry = ImportEntry.blank();
      hasValidDate = false;
      continue;
    }
    if (line.length >= _minFieldLength) {
      final String fieldLetter = line[0];
      final String fieldData = line.substring(1);
      if (inAccountBlock && fieldLetter != '!') {
        if (fieldLetter == _qifAccountFieldName) {
          currentAccountName = getNormalizedValue(fieldData);
        }
        continue;
      }
      switch (fieldLetter) {
        case '!':
          inAccountBlock = fieldData.trim() == _qifHeaderAccount;
          switch (fieldData) {
            case SharedStrings.qifTypeInvestment:
              importData.accountType = AccountType.investment;
          }

        case SharedStrings.qifFieldDate:
          // Dates may look like 01/30/2000, 1/ 5'24 or 12/31'99
          final DateTime? date = parseQifDate(getNormalizedValue(fieldData));
          hasValidDate = date != null;
          if (date != null) {
            currentEntry.date = date;
          }

        case SharedStrings.qifFieldAmount:
        case SharedStrings.qifFieldAmountAlt:
          // Amount
          currentEntry.amount = parseAmountFlexible(fieldData) ?? 0.00;

        case SharedStrings.qifFieldMemo:
          // Memo
          currentEntry.memo = getNormalizedValue(fieldData);

        case SharedStrings.qifFieldPayee:
          // Payee
          currentEntry.name = getNormalizedValue(fieldData);

        case SharedStrings.qifFieldAction:
          // Stock Action
          currentEntry.stockAction = getNormalizedValue(fieldData);

        case SharedStrings.qifFieldQuantity:
          // Quantity - We use Amount parser because quantity can have fraction
          currentEntry.stockQuantity = parseAmountFlexible(fieldData) ?? 0.0;

        case SharedStrings.qifFieldSecurity:
          // Security
          currentEntry.stockSymbol = getNormalizedValue(fieldData);

        case SharedStrings.qifFieldPrice:
          currentEntry.stockPrice = parseAmountFlexible(fieldData) ?? 0.00;
      }
    }
  }

  return importData;
}
