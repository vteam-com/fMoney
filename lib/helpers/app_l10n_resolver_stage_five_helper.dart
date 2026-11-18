import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/l10n/app_localizations.dart';

/// Last stage of [resolveAppL10nKey] (file safety, deletes and import messages);
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
    default:
      return key;
  }
}
