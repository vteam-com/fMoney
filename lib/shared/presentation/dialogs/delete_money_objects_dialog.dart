import 'package:money/data/models/data_object_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/presentation/entity_widgets/entity_widgets_helper.dart';
import 'package:money/widgets/dialogs/confirmation_dialog.dart';
import 'package:money/widgets/dialogs/message_box_dialog.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';
import 'package:money/widgets/widgets_domain/data_object_widgets_helper.dart';

/// Asks to confirm deleting [moneyObjects], called [nameSingular] or [namePlural], then deletes them and runs [onDeleted].
///
/// Says so instead when there is nothing to delete, or when other data still uses some of them.
void confirmAndDeleteMoneyObjects({
  required BuildContext context,
  required List<DataObject> moneyObjects,
  required String nameSingular,
  required String namePlural,
  VoidCallback? onDeleted,
}) {
  if (moneyObjects.isEmpty) {
    messageBox(context, AppL10n.tr(AppTranslationKeys.noItemsToDelete));
    return;
  }

  // Accounts, categories, payees and securities still in use cannot be deleted.
  final int references = Data().countBlockingReferences(moneyObjects);
  if (references > 0) {
    final Map<String, String> params = <String, String>{'count': getIntAsText(references)};
    SnackBarService.displayWarning(message: AppL10n.tr(AppTranslationKeys.deleteBlockedByReferences, params: params));
    return;
  }

  final String title = getSingularPluralText(
    AppL10n.tr(AppTranslationKeys.delete),
    moneyObjects.length,
    nameSingular,
    namePlural,
  );

  final String question = moneyObjects.length == 1
      ? AppL10n.tr(AppTranslationKeys.deleteThisItemQuestion, params: <String, String>{'item': nameSingular})
      : AppL10n.tr(
          AppTranslationKeys.deleteSelectedItemsQuestion,
          params: <String, String>{'count': getIntAsText(moneyObjects.length), 'items': namePlural},
        );
  final RenderObjectWidget content = moneyObjects.length == 1
      ? Column(
          children: buildListOfNamesValuesWidgets(
            moneyObjects.first,
            builders: entityWidgetBuilders,
            onEdit: null,
            compact: true,
          ),
        )
      : Center(
          child: Text(
            '${getIntAsText(moneyObjects.length)} $namePlural',
            style: getTextTheme(context).displaySmall,
          ),
        );

  showConfirmationDialog(
    context: context,
    title: title,
    question: question,
    content: content,
    buttonText: AppL10n.tr(AppTranslationKeys.delete),
    onConfirmation: () {
      Data().deleteItems(moneyObjects);
      onDeleted?.call();
    },
  );
}
