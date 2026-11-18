// ignore: fcheck_dead_code
import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/account_type_helper.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/views/imports/shared/data_import_view.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';

const String _skipReasonInvalidDate = 'invalidDate';
const String _skipReasonInvalidAmount = 'invalidAmount';

/// Imports QFX file and processes transactions from file path.
Future<bool> importQFX(
  BuildContext context,
  String filePath,
) async {
  final String? text = await readImportFileAsText(filePath);
  if (text == null) {
    return false;
  }
  if (!context.mounted) {
    return false;
  }

  importQfxFromString(context, text);

  return true;
}

/// Reads [filePath] as UTF-8 text, falling back to Latin-1 for legacy bank files.
/// Shows an error and returns null when the file cannot be read.
Future<String?> readImportFileAsText(String filePath) async {
  try {
    final List<int> bytes = await File(filePath).readAsBytes();
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes, allowInvalid: true);
    }
  } catch (error) {
    logger.e('Error reading file: $error');
    SnackBarService.displayError(
      autoDismiss: false,
      message: AppL10n.tr(
        AppTranslationKeys.importUnableToReadFile,
        params: <String, String>{'error': error.toString()},
      ),
    );
    return null;
  }
}

/// Processes QFX data from string content and imports transactions.
void importQfxFromString(BuildContext? context, String text) {
  final String ofx = getStringDelimitedStartEndTokens(text, '<OFX>', '</OFX>');

  final OfxBankInfo bankInfo = OfxBankInfo.fromOfx(ofx);

  final AccountType? accountType = getAccountTypeFromText(bankInfo.accountType);

  final ImportData importData = ImportData();
  // An empty ACCTID must not match an account without an account number; let the user pick instead.
  importData.account = bankInfo.accountId.trim().isEmpty
      ? null
      : Data().accounts.findByIdAndType(
          bankInfo.accountId,
          accountType,
        );
  importData.accountType = accountType;
  importData.entries = getTransactionFromOFX(ofx, diagnostics: importData.diagnostics);
  importData.fileType = SharedStrings.fileTypeQfx;
  if (context != null) {
    showImportSkippedRowsWarning(importData);
    showAndConfirmTransactionToImport(context, importData);
  }
}

/// Represents ofx bank info.
class OfxBankInfo {
  String accountId = '';
  String accountType = '';
  String id = '';

  /// Parses OFX bank information from OFX string content.
  static OfxBankInfo fromOfx(String ofx) {
    // start with this
    // <BANKACCTFROM><BANKID>123456<ACCTID>00001 99-55555<ACCTTYPE>SAVINGS</BANKACCTFROM>
    // final String bankInfoText = getStringContentBetweenTwoTokens(
    //   ofx,
    //   '<BANKACCTFROM>',
    //   '</BANKACCTFROM>',
    // );

    // Now we should have just this
    // <BANKID>123456<ACCTID>00001 99-55555<ACCTTYPE>SAVINGS
    final OfxBankInfo bankInfo = OfxBankInfo();
    bankInfo.id = findAndGetValueOf(ofx, SharedStrings.ofxTagBankId, bankInfo.id);
    bankInfo.accountId = findAndGetValueOf(ofx, SharedStrings.ofxTagAccountId, bankInfo.accountId);
    bankInfo.accountType = findAndGetValueOf(
      ofx,
      SharedStrings.ofxTagAccountType,
      bankInfo.accountType,
    );
    return bankInfo;
  }
}

// ignore: fcheck_dead_code
/// Returns investment category ID based on OFX transaction type.
int getInvestmentCategoryFromOfxType(ImportEntry ofxTransaction) {
  int categoryId = -1;
  switch (ofxTransaction.type) {
    case SharedStrings.ofxTypeCredit:
      categoryId = Data().categories.investmentCredit.fieldId.value;
      break;
    case SharedStrings.ofxTypeDebit:
      categoryId = Data().categories.investmentDebit.fieldId.value;
      break;
    case SharedStrings.ofxTypeInterest:
      categoryId = Data().categories.investmentInterest.fieldId.value;
      break;
    case SharedStrings.ofxTypeDividend:
      categoryId = Data().categories.investmentDividends.fieldId.value;
      break;
    case SharedStrings.ofxTypeFee:
    case SharedStrings.ofxTypeServiceCharge:
      categoryId = Data().categories.investmentFees.fieldId.value;
      break;
    case SharedStrings.ofxTypeDeposit:
    case SharedStrings.ofxTypeAtm:
    case SharedStrings.ofxTypePos:
    case SharedStrings.ofxTypePayment:
    case SharedStrings.ofxTypeCash:
    case SharedStrings.ofxTypeDirectDeposit:
    case SharedStrings.ofxTypeDirectDebit:
    case SharedStrings.ofxTypeRepeatPayment:
    case SharedStrings.ofxTypeCheck:
    case SharedStrings.ofxTypeOther:
      if (ofxTransaction.amount > 0) {
        categoryId = Data().categories.investmentCredit.fieldId.value;
      } else {
        categoryId = Data().categories.investmentDebit.fieldId.value;
      }
      break;
    case SharedStrings.ofxTypeTransfer:
      categoryId = Data().categories.investmentTransfer.fieldId.value;
      break;
  }
  return categoryId;
}

/// Parses OFX string content and returns list of transaction entries.
/// Skipped transactions are counted in [diagnostics] when provided.
List<ImportEntry> getTransactionFromOFX(String rawOfx, {ImportDiagnostics? diagnostics}) {
  if (rawOfx.isNotEmpty) {
    // Remove all LN/CR
    final String ofx = getNormalizedValue(rawOfx);

    String bankTransactionLit = getStringContentBetweenTwoTokens(
      ofx,
      '<BANKTRANLIST>',
      '</BANKTRANLIST>',
    );

    bankTransactionLit = bankTransactionLit.replaceAll(
      SharedStrings.ofxCloseStatementTransaction,
      SharedStrings.ofxCloseStatementTransactionLine,
    );
    final List<String> lines = LineSplitter.split(bankTransactionLit).toList();

    final List<ImportEntry> qfxTransactions = parseQFXTransactions(lines, diagnostics: diagnostics);
    return qfxTransactions;
  }

  return <ImportEntry>[];
}

/// Parses QFX transaction lines into ImportEntry objects.
/// Transactions with an unreadable amount or date are skipped and counted in [diagnostics] when provided.
List<ImportEntry> parseQFXTransactions(List<String> lines, {ImportDiagnostics? diagnostics}) {
  final List<ImportEntry> transactions = <ImportEntry>[];

  for (String line in lines) {
    line = getNormalizedValue(line);

    final String rawTransactionText = getStringContentBetweenTwoTokens(
      line,
      SharedStrings.ofxOpenStatementTransaction,
      SharedStrings.ofxCloseStatementTransaction,
    );

    if (rawTransactionText.isNotEmpty) {
      final String rawAmount = findAndGetValueOf(rawTransactionText, SharedStrings.ofxTagTransactionAmount, '0.00');
      final double? amount = parseAmountFlexible(rawAmount);
      if (amount == null) {
        logger.w('Skipping QFX transaction with malformed amount: $rawAmount');
        diagnostics?.incrementSkipped(_skipReasonInvalidAmount);
        continue;
      }
      final String rawDate = findAndGetValueOf(rawTransactionText, SharedStrings.ofxTagDatePosted, '');
      final DateTime? date = parseOfxDate(rawDate);
      if (date == null) {
        logger.w('Skipping QFX transaction with malformed date: $rawDate');
        diagnostics?.incrementSkipped(_skipReasonInvalidDate);
        continue;
      }
      final ImportEntry currentTransaction = ImportEntry(
        type: findAndGetValueOf(rawTransactionText, SharedStrings.ofxTagTransactionType, ''),
        date: date,
        amount: amount,
        name: findAndGetValueOf(rawTransactionText, SharedStrings.ofxTagName, ''),
        fitid: findAndGetValueOf(rawTransactionText, SharedStrings.ofxTagFitId, ''),
        memo: findAndGetValueOf(rawTransactionText, SharedStrings.ofxTagMemo, ''),
        number: findAndGetValueOf(rawTransactionText, SharedStrings.ofxTagCheckNumber, ''),
      );
      transactions.add(currentTransaction);
    }
  }

  return transactions;
}

/// Finds and returns value between token and closing tag, or default if not found.
String findAndGetValueOf(
  String line,
  String tokenTextToFind,
  String valueIfNotFound,
) {
  final int position = line.indexOf(tokenTextToFind);
  if (position != -1) {
    final String tokenStartingLine = line.substring(position);
    return getValuePortion(tokenStartingLine);
  }
  return valueIfNotFound;
}

/// Extracts value portion from line starting after '>' character.
String getValuePortion(String line) {
  final int startIndexOfValue = line.indexOf('>') + 1;
  String lineContent = line.substring(startIndexOfValue);

  // Find the end of the value
  int end = lineContent.indexOf('<');
  if (end == -1) {
    end = lineContent.indexOf('\n');
  }
  if (end != -1) {
    lineContent = lineContent.substring(0, end);
  }
  return getNormalizedValue(lineContent);
}
