import 'package:money/data/models/field_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/shared/domain/event_entity.dart';
import 'package:money/shared/presentation/entity_widgets/category_widgets_helper.dart';
import 'package:money/widgets/list/list_item_card.dart';
import 'package:money/widgets/pickers/category_picker_widget.dart';
import 'package:money/widgets/pickers/edit_box_date_picker_widget.dart';
import 'package:money/widgets/pickers/token_text_widget.dart';

/// Returns the [Event]-specific display widget for [field], or null for the generic one.
Widget? buildEventFieldDisplayWidget(Event event, Field<dynamic> field) {
  if (field.isSameDefinition(event.fieldCategoryId)) {
    return buildCategoryWidgetFromId(event.fieldCategoryId.value);
  }
  if (field.isSameDefinition(event.fieldName)) {
    return TokenText(event.eventName);
  }
  return null;
}

/// Returns the [Event]-specific editor for [field], or null for the generic one.
Widget? buildEventFieldEditWidget(
  Event event,
  Field<dynamic> field,
  void Function(bool /* wasModified */) onEdited,
) {
  if (field.isSameDefinition(event.fieldCategoryId)) {
    return pickerCategory(
      key: const Key('key_pick_category'),
      categoryNames: event.data!.getCategoriesAsStrings(),
      selectedName: event.data!.getCategoryNameFromId(event.fieldCategoryId.value),
      onSelected: (String? name) {
        final int? newId = event.data!.getCategoryIdFromName(name!);
        if (newId != null) {
          event.fieldCategoryId.value = newId;
          // notify container
          onEdited(true);
        }
      },
    );
  }
  if (field.isSameDefinition(event.fieldDateBegin)) {
    return _buildEventDateEditWidget(event.fieldDateBegin, onEdited);
  }
  if (field.isSameDefinition(event.fieldDateEnd)) {
    return _buildEventDateEditWidget(event.fieldDateEnd, onEdited);
  }
  return null;
}

/// Builds the small-screen card for an event.
Widget buildEventSmallScreenWidget(Event _) {
  return MyListItemAsCard(
    leftTopAsString: AppL10n.tr(AppTranslationKeys.begin),
    rightTopAsString: AppL10n.tr(AppTranslationKeys.end),
    rightBottomAsString: AppL10n.tr(AppTranslationKeys.memo),
  );
}

/// Builds the date picker editor for one of the event date [dateField]s.
Widget _buildEventDateEditWidget(FieldDate dateField, void Function(bool /* wasModified */) onEdited) {
  return PickerEditBoxDate(
    key: Constants.keyDatePicker,
    initialValue: dateToDateTimeString(dateField.value),
    onChanged: (String? newDateSelected) {
      if (newDateSelected != null) {
        dateField.value = attemptToGetDateFromText(
          newDateSelected,
        );
        onEdited(true);
      }
    },
  );
}
