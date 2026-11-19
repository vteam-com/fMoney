import 'package:money/data/models/data_object_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/payee_operations_interface.dart';
import 'package:money/widgets/list/list_item_card.dart';
import 'package:money/widgets/pickers/edit_box_picker_widget.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

/// Builds the small-screen card for [payee].
Widget buildPayeeSmallScreenWidget(Payee payee) {
  return MyListItemAsCard(
    leftTopAsString: payee.fieldName.value,
    rightTopAsWidget: WidgetFromData(
      amountModel: payee.fieldSum.value,
      size: DataWidgetSize.title,
    ),
    rightBottomAsString: getAmountAsShorthandText(payee.fieldCount.value),
  );
}

/// A payee box listing [data]'s payees, with an Add button for a new name: [onSelected] receives
/// the payee typed or picked, null while the text names none, and the payee created by Add.
Widget pickerPayee({
  required PayeeOperations data,
  required void Function(DataObject? payee) onSelected,
  String? selectedName,
  Key? key,
}) {
  return PickerEditBox(
    key: key,
    title: AppL10n.tr(AppTranslationKeys.payee),
    items: data.getPayeeNamesSorted(),
    initialValue: selectedName,
    onChanged: (String name) => onSelected(data.getPayeeByName(name)),
    onAddNew: (String name) => onSelected(data.getOrCreatePayee(name)),
  );
}
