import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';

/// What the user chose when asked about unsaved changes.
enum UnsavedChangesChoice { save, discard, cancel }

/// Asks whether to save or discard [numberOfChanges] unsaved changes before continuing.
///
/// Dismissing the dialog counts as [UnsavedChangesChoice.cancel], so nothing is lost by accident.
Future<UnsavedChangesChoice> showUnsavedChangesDialog(BuildContext context, int numberOfChanges) async {
  final UnsavedChangesChoice? choice = await showDialog<UnsavedChangesChoice>(
    context: context,
    builder: (BuildContext dialogContext) {
      /// Closes the dialog with [result].
      void close(UnsavedChangesChoice result) => Navigator.of(dialogContext).pop(result);

      return AlertDialog(
        title: Text(AppL10n.tr(AppTranslationKeys.unsavedChanges)),
        content: Text(
          AppL10n.tr(
            AppTranslationKeys.unsavedChangesMessage,
            params: <String, String>{'count': '$numberOfChanges'},
          ),
        ),
        actions: <Widget>[
          DialogActionButton(
            text: AppL10n.tr(AppTranslationKeys.cancel),
            onPressed: () => close(UnsavedChangesChoice.cancel),
          ),
          DialogActionButton(
            text: AppL10n.tr(AppTranslationKeys.discardChanges),
            onPressed: () => close(UnsavedChangesChoice.discard),
          ),
          DialogActionButton(
            text: AppL10n.tr(AppTranslationKeys.save),
            icon: Icons.save,
            onPressed: () => close(UnsavedChangesChoice.save),
          ),
        ],
      );
    },
  );
  return choice ?? UnsavedChangesChoice.cancel;
}
