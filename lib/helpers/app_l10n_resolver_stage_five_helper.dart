import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/l10n/app_localizations.dart';

/// Last stage of [resolveAppL10nKey] (file safety, deletes, import and reconciliation messages);
/// returns [key] itself when it is unknown.
String resolveAppL10nKeyStageFive(AppLocalizations l10n, String key, Map<String, String> p) {
  switch (key) {
    case AppTranslationKeys.deleteBlockedByReferences:
      return l10n.deleteBlockedByReferences(p['count'] ?? '');
    case AppTranslationKeys.cannotMoveCategoryUnderItself:
      return l10n.cannotMoveCategoryUnderItself;
    case AppTranslationKeys.importFileHasMultipleAccounts:
      return l10n.importFileHasMultipleAccounts(p['fileType'] ?? '', p['count'] ?? '');
    case AppTranslationKeys.importInvalidNumberEntered:
      return l10n.importInvalidNumberEntered;
    case AppTranslationKeys.importRowsParsedAndSkipped:
      return l10n.importRowsParsedAndSkipped(p['fileType'] ?? '', p['imported'] ?? '', p['skipped'] ?? '');
    case AppTranslationKeys.importUnableToReadFile:
      return l10n.importUnableToReadFile(p['error'] ?? '');
    case AppTranslationKeys.unsavedChanges:
      return l10n.unsavedChanges;
    case AppTranslationKeys.unsavedChangesMessage:
      return l10n.unsavedChangesMessage(p['count'] ?? '');
    case AppTranslationKeys.discardChanges:
      return l10n.discardChanges;
    case AppTranslationKeys.save:
      return l10n.save;
    case AppTranslationKeys.saveAs:
      return l10n.saveAs;
    case AppTranslationKeys.fileNoLongerExists:
      return l10n.fileNoLongerExists(p['fileName'] ?? '');
    case AppTranslationKeys.fileChangedOnDisk:
      return l10n.fileChangedOnDisk(p['fileName'] ?? '');
    case AppTranslationKeys.clearedBalance:
      return l10n.clearedBalance;
    case AppTranslationKeys.difference:
      return l10n.difference;
    case AppTranslationKeys.finish:
      return l10n.finish;
    case AppTranslationKeys.lastReconciled:
      return l10n.lastReconciled;
    case AppTranslationKeys.never:
      return l10n.never;
    case AppTranslationKeys.reconcileInstructions:
      return l10n.reconcileInstructions;
    case AppTranslationKeys.reconcileWithStatement:
      return l10n.reconcileWithStatement;
    case AppTranslationKeys.reconciledBalance:
      return l10n.reconciledBalance;
    case AppTranslationKeys.reconciledTransactionsCount:
      return l10n.reconciledTransactionsCount(p['count'] ?? '');
    case AppTranslationKeys.start:
      return l10n.start;
    case AppTranslationKeys.statementDate:
      return l10n.statementDate;
    default:
      return key;
  }
}
