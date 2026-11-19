import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/presentation/entity_widgets/alias_pattern_editor_widget.dart';
import 'package:money/shared/presentation/entity_widgets/payee_widgets_helper.dart';
import 'package:money/widgets/list/list_item_card.dart';
import 'package:money/widgets/pickers/edit_box_picker_widget.dart';

/// Builds the small-screen card for [alias].
Widget buildAliasSmallScreenWidget(Alias alias) {
  return MyListItemAsCard(
    leftTopAsString: alias.payeeName,
    leftBottomAsString: alias.fieldPattern.value,
    rightBottomAsString: '${getAliasTypeAsString(alias.type)}${SharedDomainStrings.domainString158}',
  );
}

/// Returns the alias-specific editor for [field] of [alias] (pattern with its explanation, payee and type
/// pickers), or null for the generic one.
Widget? buildAliasFieldEditWidget(
  Alias alias,
  Field<dynamic> field,
  void Function(bool /* wasModified */) onEdited,
) {
  if (field.isSameDefinition(alias.fieldPattern)) {
    return AliasPatternEditor(alias: alias, onEdited: onEdited);
  }
  if (field.isSameDefinition(alias.fieldPayeeId)) {
    return pickerPayee(
      key: const Key('key_pick_alias_payee'),
      data: alias.data!,
      selectedName: alias.payeeName,
      onSelected: (DataObject? payee) {
        if (payee != null) {
          alias.fieldPayeeId.value = payee.uniqueId;
          onEdited(true);
        }
      },
    );
  }
  if (field.isSameDefinition(alias.fieldFlags)) {
    return pickerEnum<AliasType>(
      key: const Key('key_pick_alias_type'),
      title: field.name,
      values: AliasType.values,
      selected: alias.type,
      toText: getAliasTypeAsString,
      onSelected: (AliasType type) {
        alias.fieldFlags.value = type.index;
        onEdited(true);
      },
    );
  }
  return null;
}
