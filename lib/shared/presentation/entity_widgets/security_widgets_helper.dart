import 'package:money/data/models/field_model.dart';
import 'package:money/shared/domain/security_entity.dart';
import 'package:money/widgets/list/list_item_card.dart';
import 'package:money/widgets/pickers/picker_security_type.dart';
import 'package:money/widgets/pure/quantity_widget.dart';
import 'package:money/widgets/widgets_domain/field_widgets_helper.dart';

/// Returns the [Security]-specific editor for [field], or null for the generic one.
Widget? buildSecurityFieldEditWidget(
  Security security,
  Field<dynamic> field,
  void Function(bool /* wasModified */) onEdited,
) {
  if (field.isSameDefinition(security.fieldSecurityType)) {
    return pickerSecurityType(
      itemSelected: SecurityType.values[security.fieldSecurityType.value],
      onSelected: (SecurityType? newSecurityType) {
        if (newSecurityType != null) {
          security.fieldSecurityType.value = newSecurityType.index;
          // notify container
          onEdited(true);
        }
      },
    );
  }
  return null;
}

/// Builds the small-screen card for [security].
Widget buildSecuritySmallScreenWidget(Security security) {
  return MyListItemAsCard(
    leftTopAsString: security.fieldSymbol.value,
    leftBottomAsWidget: QuantityWidget(
      quantity: security.fieldHoldingShares.value.toDouble(),
      align: TextAlign.left,
    ),
    rightTopAsWidget: buildFieldValueWidget(security, security.fieldProfit),
    rightBottomAsWidget: buildFieldValueWidget(security, security.fieldHoldingValue),
  );
}
