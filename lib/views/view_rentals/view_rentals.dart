import 'package:money/data/data.dart';
import 'package:money/data/rent_building.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/models/rental_unit.dart';
import 'package:money/views/adaptive_view/view_money_objects.dart';
import 'package:money/views/money_object_card.dart';
import 'package:money/views/panels/side_panel/side_panel_support.dart';
import 'package:money/views/view_rentals/view_rentals_side_panel.dart';
import 'package:money/widgets/center_message.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/widgets_domain/cd/field.dart';
import 'package:money/widgets/widgets_domain/cd/money_object.dart';

class ViewRentals extends ViewForMoneyObjects {
  const ViewRentals({super.key});

  @override
  State<ViewForMoneyObjects> createState() => ViewRentalsState();
}

class ViewRentalsState extends ViewForMoneyObjectsState {
  ViewRentalsState() {
    viewId = ViewId.viewRentals;
  }

  RentBuilding? lastSelectedRental;

  @override
  String getClassNamePlural() {
    return 'Rentals';
  }

  @override
  String getClassNameSingular() {
    return 'Rental';
  }

  @override
  String getDescription() {
    return 'Properties to rent.';
  }

  @override
  Fields<RentBuilding> getFieldsForTable() {
    return RentBuilding.fieldsForColumnView;
  }

  @override
  List<RentBuilding> getList({
    bool includeDeleted = false,
    bool applyFilter = true,
  }) {
    final List<RentBuilding> list = Data().rentBuildings.iterableList(includeDeleted: includeDeleted).toList();

    return list;
  }

  @override
  SidePanelSupport getSidePanelSupport() {
    return SidePanelSupport(
      onDetails: getSidePanelViewDetails,
      onChart: ViewRentalsSidePanel.getSubViewContentForChart,
      onPnL: ViewRentalsSidePanel.getSubViewContentForPnL,
      onTransactions: ViewRentalsSidePanel.getSubViewContentForTransactions,
    );
  }

  @override
  List<MoneyObject> getSidePanelTransactions() {
    final RentBuilding? item = getFirstSelectedItem() as RentBuilding?;
    if (item == null) {
      return <MoneyObject>[];
    }
    return ViewRentalsSidePanel.getTransactionLastSelectedItem(item);
  }

  @override
  Widget getSidePanelViewDetails({
    required final List<int> selectedIds,
    required final bool isReadOnly,
  }) {
    final RentBuilding? selectedItem = getFirstSelectedItem() as RentBuilding?;
    if (selectedItem == null) {
      return const CenterMessage(message: 'No item selected.');
    }

    return SingleChildScrollView(
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          runSpacing: 30,
          spacing: 30,
          children: <Widget>[
            MoneyObjectCard(
              title: getClassNameSingular(),
              moneyObject: selectedItem,
            ),
            buildRenters(context, selectedItem),
          ],
        ),
      ),
    );
  }

  Widget buildRenters(final BuildContext context, final RentBuilding building) {
    final List<RentUnit> rentersInThisBuilding = Data().rentUnits
        .iterableList()
        .where(
          (RentUnit item) => item.fieldBuilding.value == building.uniqueId,
        )
        .toList();

    return buildAdaptiveBox(
      context: context,
      title: 'Renters',
      content: ListView.separated(
        itemCount: rentersInThisBuilding.length,
        itemBuilder: (BuildContext context, int index) {
          final RentUnit renter = rentersInThisBuilding[index];
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(renter.fieldName.value),
              gapLarge(),
              Expanded(child: Text(renter.fieldRenter.value)),
              gapLarge(),
              Text(renter.fieldNote.value),
            ],
          );
        },
        separatorBuilder: (BuildContext context, int index) => Divider(
          color: getColorTheme(context).onPrimaryContainer.withAlpha(100),
        ),
      ),
      count: rentersInThisBuilding.length,
    );
  }

  String getUnitsAsString(final List<RentUnit> listOfUnits) {
    final List<String> listAsText = <String>[];
    for (RentUnit unit in listOfUnits) {
      listAsText.add('${unit.fieldName}:${unit.fieldRenter}');
    }

    return listAsText.join('\n');
  }
}
