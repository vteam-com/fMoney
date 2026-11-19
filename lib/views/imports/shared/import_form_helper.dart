import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/widgets/dialogs/dialog_widget.dart';
import 'package:money/widgets/pickers/category_picker_widget.dart';
import 'package:money/widgets/pickers/edit_box_date_picker_widget.dart';
import 'package:money/widgets/pure/form_field_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';

/// Shows a manual import [panel] in an adaptive dialog with a Cancel button followed by [actionButtons].
void showImportFormDialog({
  required BuildContext context,
  required Widget panel,
  required List<Widget> actionButtons,
}) {
  adaptiveScreenSizeDialog(
    context: context,
    captionForClose: AppL10n.tr(AppTranslationKeys.cancel),
    actionButtons: actionButtons,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        gapLarge(),
        Expanded(child: panel),
      ],
    ),
  );
}

/// Builds the Date field of a manual import form starting at [date]; [onChanged] receives each typed or picked date,
/// or today when the text is not a date.
Widget buildImportDateField({
  required DateTime date,
  required void Function(DateTime date) onChanged,
}) {
  return myFormField(
    title: AppL10n.tr(AppTranslationKeys.date),
    child: PickerEditBoxDate(
      initialValue: dateToString(date),
      onChanged: (String newDateSelected) {
        onChanged(attemptToGetDateFromText(newDateSelected) ?? DateTime.now());
      },
    ),
  );
}

/// Builds the Category field of a manual import form showing [category];
/// [onChanged] receives each category picked by name.
Widget buildImportCategoryField({
  required Category? category,
  required void Function(Category category) onChanged,
}) {
  return myFormField(
    title: AppL10n.tr(AppTranslationKeys.category),
    child: pickerCategory(
      categoryNames: Data().categories.getCategoriesAsStrings(),
      selectedName: category?.fieldName.value,
      onSelected: (String? name) {
        final Category? newSelection = name != null ? Data().categories.getByName(name) : null;
        if (newSelection != null) {
          onChanged(newSelection);
        }
      },
    ),
  );
}
