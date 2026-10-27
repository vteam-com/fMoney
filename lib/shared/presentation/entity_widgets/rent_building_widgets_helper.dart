import 'package:money/helpers/amount_model.dart';
import 'package:money/shared/domain/rent_building_entity.dart';
import 'package:money/widgets/list/list_item_card.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

/// Returns the [RentBuilding]-specific display widget for [field], or null for the generic one.
Widget? buildRentBuildingFieldDisplayWidget(RentBuilding building, Field<dynamic> field) {
  if (field.isSameDefinition(building.fieldCurrency)) {
    return buildCurrencyWidget(building.getCurrencyOfAssociatedAccount());
  }
  return null;
}

/// Builds the small-screen card for [building].
Widget buildRentBuildingSmallScreenWidget(RentBuilding building) {
  return MyListItemAsCard(
    leftTopAsString: building.fieldName.value,
    leftBottomAsString: building.fieldAddress.value,
    rightTopAsWidget: WidgetFromData(
      amountModel: AmountModel(amount: building.lifeTimePnL.profit),
      size: DataWidgetSize.title,
    ),
  );
}
