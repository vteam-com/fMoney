import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/widgets/list/list_item_card.dart';
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
