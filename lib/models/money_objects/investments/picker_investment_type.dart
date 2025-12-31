import 'package:money/views/home/sub_views/view_stocks/picker_security_type.dart';
import 'package:money/widgets/picker_edit_box.dart';

Widget pickerInvestmentType({
  required final InvestmentType itemSelected,
  required final void Function(InvestmentType) onSelected,
}) {
  final String selectedName = getInvestmentTypeText(itemSelected);

  return PickerEditBox(
    title: 'Investment type',
    items: getInvestmentTypeNames(),
    initialValue: selectedName,
    onChanged: (String newSelection) {
      onSelected(getInvestmentTypeFromText(newSelection));
    },
  );
}
