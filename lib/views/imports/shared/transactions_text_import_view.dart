// ignore: fcheck_magic_numbers
import 'dart:async';
import 'dart:math';

import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_logger_helper.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/bank_statement_pdf_service.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/views/imports/shared/ai_pdf_import_service.dart';
import 'package:money/views/imports/shared/transactions_import_panel.dart';
import 'package:money/widgets/columns/value_parser.dart';
import 'package:money/widgets/columns/value_quality.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/dialogs/dialog_widget.dart';
import 'package:money/widgets/dialogs/message_box_dialog.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';
import 'package:money/widgets/pure/working_indicator_widget.dart';

const int _isoDateLength = 10;
const int _matchingLast4Digits = 4;
const double _pdfImportLoadingSpacing = 12.0;
const double _pdfImportLoadingPadding = 18.0;

/// Shows a loading dialog, parses [pdfFilePath] with AI, and opens the regular transaction import panel pre-filled.
Future<void> showImportTransactionsFromPdfUsingAi({
  required BuildContext context,
  required String pdfFilePath,
  AiPdfImportService aiPdfImportService = const AiPdfImportService(),
}) async {
  if (pdfFilePath.isEmpty) {
    return;
  }

  final NavigatorState rootNavigator = Navigator.of(context, rootNavigator: true);
  _showPdfImportLoadingDialog(rootNavigator);

  BankStatementParseResult? statement;
  try {
    statement = await aiPdfImportService.parsePdfStatement(filePath: pdfFilePath);
  } catch (e, stackTrace) {
    AppLogger.error(
      module: 'transactions_text_import_view',
      operation: 'showImportTransactionsFromPdfUsingAi',
      error: e,
      stackTrace: stackTrace,
    );
    statement = null;
  } finally {
    _closePdfImportLoadingDialog(rootNavigator);
  }

  if (statement == null) {
    _showPdfImportMessageDialog(
      message: AppL10n.tr(AppTranslationKeys.aiUnableToReadPdf),
    );
    return;
  }

  if (!statement.isBankStatement || statement.transactions.isEmpty) {
    _showPdfImportMessageDialog(
      message: AppL10n.tr(AppTranslationKeys.aiPdfNotBankStatement),
    );
    return;
  }

  if (!context.mounted) {
    return;
  }

  final Account? matchedAccount = _findMatchingAccountForStatement(statement);
  if (matchedAccount != null) {
    Data().accounts.setMostRecentUsedAccount(matchedAccount);
  } else {
    final String? unmatchedAccountIdentifier = _findUnmatchedAccountIdentifier(statement);
    if (unmatchedAccountIdentifier != null) {
      await _showUnmatchedAccountDialog(
        context: context,
        accountIdentifier: unmatchedAccountIdentifier,
      );
      if (!context.mounted) {
        return;
      }
    }
  }

  final String initialText = _buildImportTextFromStatement(statement);
  final String preferredCurrencyCode =
      _resolvePreferredCurrencyCode(statement) ??
      Data().accounts.getMostRecentlySelectedAccount().getAccountCurrencyAsText();
  showImportTransactionsFromTextInput(
    context,
    initialText,
    preferredCurrencyCode,
  );
}

/// Shows a non-dismissible loading dialog used while AI is starting and parsing the PDF.
void _showPdfImportLoadingDialog(NavigatorState rootNavigator) {
  unawaited(
    showDialog<void>(
      context: rootNavigator.context,
      barrierDismissible: false,
      builder: (BuildContext _) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Padding(
              padding: const EdgeInsets.all(_pdfImportLoadingPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: _pdfImportLoadingSpacing,
                children: <Widget>[
                  const WorkingIndicator(),
                  Text(AppL10n.tr(AppTranslationKeys.checkingOllamaStatus)),
                  Text(AppL10n.tr(AppTranslationKeys.aiReadingPdfStatement)),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// Closes the loading dialog shown by [_showPdfImportLoadingDialog] if it is still visible.
void _closePdfImportLoadingDialog(NavigatorState rootNavigator) {
  if (rootNavigator.canPop()) {
    rootNavigator.pop();
  }
}

/// Shows a guaranteed modal feedback message for PDF import outcomes.
void _showPdfImportMessageDialog({
  required String message,
}) {
  final BuildContext? routerContext = AppRouter.context;
  if (routerContext == null) {
    AppLogger.debug(
      module: 'transactions_text_import_view',
      operation: '_showPdfImportMessageDialog',
      message: 'Unable to show PDF import dialog because AppRouter context is null.',
    );
    return;
  }

  messageBox(routerContext, message);
}

/// Converts parsed statement transactions into semicolon-delimited text for [ImportTransactionsPanel].
String _buildImportTextFromStatement(BankStatementParseResult statement) {
  final List<String> lines = statement.transactions.map((BankStatementTransactionRecord record) {
    final String dateText = _formatStatementDateForImport(record.date);
    final String description = _sanitizeStatementDescription(record.description);
    final String amount = record.amount;
    return '$dateText; $description; $amount';
  }).toList();

  final String importText = lines.join('\n');

  return importText;
}

/// Formats a [date] into an ISO-like day token accepted by the import panel parsers.
String _formatStatementDateForImport(DateTime date) {
  final String isoDate = date.toIso8601String();
  if (isoDate.length <= _isoDateLength) {
    return isoDate;
  }
  return isoDate.substring(0, _isoDateLength);
}

/// Sanitizes statement [description] to avoid delimiter collisions in semicolon-delimited import text.
String _sanitizeStatementDescription(String description) {
  return description.replaceAll(';', ' ').replaceAll('\n', ' ').replaceAll('\r', ' ').trim();
}

/// Finds the best matching local account for [statement] using extracted account hints.
Account? _findMatchingAccountForStatement(BankStatementParseResult statement) {
  if (statement.accountHints.isEmpty) {
    return null;
  }

  final List<Account> accounts = Data().accounts
      .getOpenRealAccounts()
      .where((Account account) => !account.isFakeAccount())
      .toList();

  Account? bestAccount;
  int bestScore = 0;
  for (final Account account in accounts) {
    final int score = _calculateAccountMatchScore(account: account, accountHints: statement.accountHints);
    if (score > bestScore) {
      bestScore = score;
      bestAccount = account;
    }
  }

  return bestScore > 0 ? bestAccount : null;
}

/// Calculates a matching score between [account] and [accountHints].
int _calculateAccountMatchScore({
  required Account account,
  required List<String> accountHints,
}) {
  int score = 0;

  final String normalizedAccountId = _normalizeMatchToken(account.fieldAccountId.value);
  final String normalizedOfxAccountId = _normalizeMatchToken(account.fieldOfxAccountId.value);
  final String normalizedAccountName = _normalizeMatchToken(account.fieldName.value);
  final String accountIdDigits = _extractDigits(normalizedAccountId);
  final String ofxAccountIdDigits = _extractDigits(normalizedOfxAccountId);

  for (final String hint in accountHints) {
    final String normalizedHint = _normalizeMatchToken(hint);
    if (normalizedHint.isEmpty) {
      continue;
    }

    if (normalizedHint == normalizedAccountId) {
      score = max(score, 100);
    }
    if (normalizedHint == normalizedOfxAccountId) {
      score = max(score, 95);
    }
    if (normalizedAccountName.contains(normalizedHint)) {
      score = max(score, 50);
    }

    final String hintDigits = _extractDigits(normalizedHint);
    if (hintDigits.length >= _matchingLast4Digits) {
      final String last4 = hintDigits.substring(hintDigits.length - _matchingLast4Digits);
      if (accountIdDigits.length >= _matchingLast4Digits && accountIdDigits.endsWith(last4)) {
        score = max(score, 80);
      }
      if (ofxAccountIdDigits.length >= _matchingLast4Digits && ofxAccountIdDigits.endsWith(last4)) {
        score = max(score, 75);
      }
    }
  }

  return score;
}

/// Normalizes account match tokens by removing non-alphanumeric characters and uppercasing.
String _normalizeMatchToken(String token) {
  return token.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
}

/// Extracts only digits from [token].
String _extractDigits(String token) {
  return token.replaceAll(RegExp(r'[^0-9]'), '');
}

/// Returns the first account identifier hint with at least four digits, when present.
String? _findUnmatchedAccountIdentifier(BankStatementParseResult statement) {
  for (final String hint in statement.accountHints) {
    final String trimmedHint = hint.trim();
    if (trimmedHint.isEmpty) {
      continue;
    }

    if (_extractDigits(trimmedHint).length >= _matchingLast4Digits) {
      return trimmedHint;
    }
  }

  return null;
}

/// Resolves a normalized preferred import currency code from [statement].
String? _resolvePreferredCurrencyCode(BankStatementParseResult statement) {
  final String? detectedCurrencyCode = statement.detectedCurrencyCode;
  if (detectedCurrencyCode == null) {
    return null;
  }

  final String normalizedCode = detectedCurrencyCode.trim().toUpperCase();
  if (normalizedCode.isEmpty) {
    return null;
  }

  if (normalizedCode == SharedStrings.currencyUsd || normalizedCode == Constants.defaultCurrency) {
    return SharedStrings.currencyUsd;
  }

  return normalizedCode;
}

/// Shows a dialog notifying that [accountIdentifier] could not be matched to any local account.
Future<void> _showUnmatchedAccountDialog({
  required BuildContext context,
  required String accountIdentifier,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(AppL10n.tr(AppTranslationKeys.aiNoMatchingAccountFound)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(AppL10n.tr(AppTranslationKeys.aiStatementAccountFoundLabel)),
            gapSmall(),
            SelectableText(accountIdentifier),
            gapMedium(),
            Text(AppL10n.tr(AppTranslationKeys.aiStatementAccountNotFoundSelectDestinationAccount)),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: Text(AppL10n.tr(AppTranslationKeys.continueLabel)),
          ),
        ],
      );
    },
  );
}

/// Shows dialog for importing transactions from text input with optional [preferredCurrencyCode].
void showImportTransactionsFromTextInput(
  BuildContext context, [
  String? initialText,
  String? preferredCurrencyCode,
]) {
  initialText ??= '';

  Account account = Data().accounts.getMostRecentlySelectedAccount();

  final ValuesParser parser = ValuesParser(
    dateFormat: 'MM/dd/yyyy',
    currency: SharedStrings.currencyUsd,
  );

  final List<Widget> actionButtons = <Widget>[
    // Button - Import
    DialogActionButton(
      text: AppL10n.tr(AppTranslationKeys.importWord),
      onPressed: () {
        if (parser.isEmpty) {
          messageBox(context, AppL10n.tr(AppTranslationKeys.nothingToImport));
        } else {
          // Import
          final List<Transaction> transactionsToAdd = <Transaction>[];

          for (final ValuesQuality singleTransactionInput in parser.lines) {
            if (!singleTransactionInput.exist) {
              final Transaction t = Transaction.fromDateDescriptionAmount(
                account,
                singleTransactionInput.date.asDate() ?? DateTime.now(),
                singleTransactionInput.description.asString(),
                singleTransactionInput.amount.asAmount(),
              );
              transactionsToAdd.add(t);
            }
          }
          addNewTransactions(
            transactionsToAdd,
            AppL10n.tr(
              AppTranslationKeys.transactionsAddedCount,
              params: <String, String>{'count': transactionsToAdd.length.toString()},
            ),
          );

          Navigator.of(context).pop(false);
        }
      },
    ),
  ];

  adaptiveScreenSizeDialog(
    context: context,
    captionForClose: AppL10n.tr(AppTranslationKeys.cancel),
    actionButtons: actionButtons,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        gapLarge(),
        Expanded(
          child: ImportTransactionsPanel(
            account: account,
            inputText: initialText,
            preferredCurrencyCode: preferredCurrencyCode,
            onAccountChanged: (Account accountSelected) {
              account = accountSelected;
              Data().accounts.setMostRecentUsedAccount(accountSelected);
            },
            onTransactionsFound: (ValuesParser newParser) {
              parser.lines = newParser.lines;
            },
          ),
        ),
      ],
    ),
  );
}

/// Add the list of transactions "as is", then notify the user when completed
/// Note that this does not check for duplicated transaction or resolves the Payee names
void addNewTransactions(
  List<Transaction> transactionsNew,
  String messageToUserAfterAdding,
) {
  if (transactionsNew.isEmpty) {
    SnackBarService.displayWarning(
      autoDismiss: true,
      message: messageToUserAfterAdding,
    );
    return;
  }

  for (final Transaction transactionToAdd in transactionsNew) {
    Data().transactions.appendNewMoneyObject(
      transactionToAdd,
      fireNotification: false,
    );
  }
  Data().updateAll();

  SnackBarService.displaySuccess(
    autoDismiss: true,
    title: AppL10n.tr(AppTranslationKeys.importWord),
    message: messageToUserAfterAdding,
  );
}
