import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/shared/domain/data.dart';
import 'package:money/shared/domain/rent_building.dart';
import 'package:money/shared/domain/rental_unit.dart';
import 'package:money/shared/presentation/money_object_card.dart';
import 'package:money/views/panels/core/side_panel_support.dart';
import 'package:money/views/panels/core/view_money_objects.dart';
import 'package:money/views/panels/core/view_rentals_side_panel.dart';
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
    return AppL10n.tr(AppTranslationKeys.rentals);
  }

  @override
  String getClassNameSingular() {
    return AppL10n.tr(AppTranslationKeys.rental);
  }

  @override
  String getDescription() {
    return AppL10n.tr(AppTranslationKeys.propertiesToRentDescription);
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
    keepUnused(selectedIds);
    final RentBuilding? selectedItem = getFirstSelectedItem() as RentBuilding?;
    return buildStandardSidePanelDetailsWrap<RentBuilding>(
      selectedItem: selectedItem,
      spacing: _panelSpacing,
      extraPanels: <Widget>[
        if (selectedItem != null) buildRenters(context, selectedItem),
      ],
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
      title: AppL10n.tr(AppTranslationKeys.renters),
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
