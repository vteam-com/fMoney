import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/providers/rent_building.dart';
import 'package:money/providers/rental_unit.dart';
import 'package:money/views/adaptive_view/view_money_objects.dart';
import 'package:money/views/data.dart';
import 'package:money/views/money_object_card.dart';
import 'package:money/views/panels/side_panel/side_panel_support.dart';
import 'package:money/views/view_rentals/view_rentals_side_panel.dart';
import 'package:money/widgets/pure/center_message.dart';
import 'package:money/widgets/pure/gaps.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';

const double _panelSpacing = 30.0;
const int _dividerAlpha = 100;

/// Represents view rentals.
class ViewRentals extends ViewForMoneyObjects {
  const ViewRentals({super.key});

  @override
  State<ViewForMoneyObjects> createState() => _ViewRentalsState();
}

class _ViewRentalsState extends ViewForMoneyObjectsState {
  _ViewRentalsState() {
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
  List<DataObject> getSidePanelTransactions() {
    final RentBuilding? item = getFirstSelectedItem() as RentBuilding?;
    if (item == null) {
      return <DataObject>[];
    }
    return ViewRentalsSidePanel.getTransactionLastSelectedItem(item);
  }

  @override
  Widget getSidePanelViewDetails({required final List<int> selectedIds}) {
    final RentBuilding? selectedItem = getFirstSelectedItem() as RentBuilding?;
    if (selectedItem == null) {
      return const CenterMessage(message: 'No item selected.');
    }

    return SingleChildScrollView(
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          runSpacing: _panelSpacing,
          spacing: _panelSpacing,
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

  /// Builds a renters list for the given building.
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
        itemBuilder: (BuildContext _, int index) {
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
        separatorBuilder: (BuildContext context, int _) => Divider(
          color: getColorTheme(context).onPrimaryContainer.withAlpha(_dividerAlpha),
        ),
      ),
      count: rentersInThisBuilding.length,
    );
  }
}
