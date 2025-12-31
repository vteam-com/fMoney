import 'package:money/views/home/sub_views/view_stocks/picker_security_type.dart';
import 'package:money/widgets/picker_edit_box.dart';

enum InvestmentTradeType {
  none, // 0
  buy, // 1
  buyToOpen, // 2
  buyToCover, // 3,
  buyToClose, // 4,
  sell, // 5
  sellShort, // 6
}

String getInvestmentTradeTypeText(final InvestmentTradeType type) {
  return type.name.toUpperCase();
}

String getInvestmentTradeTypeTextFromValue(final int value) {
  return getInvestmentTradeTypeText(getInvestmentTradeTypeFromValue(value));
}

InvestmentTradeType getInvestmentTradeTypeFromValue(final int value) {
  return InvestmentTradeType.values[value];
}

InvestmentTradeType getInvestmentTradeTypeFromText(final String name) {
  return InvestmentTradeType.values.byName(name);
}

List<String> getInvestmentTradeTypeNames() {
  return InvestmentTradeType.values.map((InvestmentTradeType item) => item.toString().split('.').last).toList();
}

InvestmentTradeType fromInvestmentType(final InvestmentType type) {
  switch (type) {
    case InvestmentType.buy:
    case InvestmentType.add:
      return InvestmentTradeType.buy;
    case InvestmentType.sell:
    case InvestmentType.remove:
      return InvestmentTradeType.sell;
    case InvestmentType.dividend:
    case InvestmentType.none:
      return InvestmentTradeType.none;
  }
}

Widget pickerInvestmentTradeType({
  required final InvestmentTradeType itemSelected,
  required final void Function(InvestmentTradeType) onSelected,
}) {
  final String selectedName = getInvestmentTradeTypeText(itemSelected);

  return PickerEditBox(
    title: 'Investment Trade Type',
    items: getInvestmentTradeTypeNames(),
    initialValue: selectedName,
    onChanged: (String newSelection) {
      onSelected(getInvestmentTradeTypeFromText(newSelection));
    },
  );
}
