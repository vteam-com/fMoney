import 'package:money/controller/list_controller.dart';
import 'package:money/controller/selection_controller.dart';
import 'package:money/data/storage/data/data.dart';
import 'package:money/models/money_objects/rent_buildings/rent_building.dart';
import 'package:money/models/money_objects/splits/money_split.dart';
import 'package:money/models/money_objects/transactions/transaction.dart';
import 'package:money/views/home/sub_views/adaptive_view/adaptive_list/transactions/list_view_transactions.dart';
import 'package:money/views/home/sub_views/view_rentals/rental_pnl.dart';
import 'package:money/views/home/sub_views/view_rentals/rental_pnl_card.dart';
import 'package:money/widgets/chart.dart';

/// Contains the logic for the side panel in the View Rentals screen.
class ViewRentalsSidePanel {
  /// Filters transactions based on whether their categories match the rental property's categories for income, management, repairs, maintenance, taxes or interest.
  ///
  /// Considers split transactions by checking each split individually.
  static bool filterByRentalCategories(
    final Transaction t,
    final RentBuilding rental,
  ) {
    final num categoryIdToMatch = t.fieldCategoryId.value;

    if (t.isSplit) {
      for (final MoneySplit split in t.splits) {
        if (isMatchingCategories(split.fieldCategoryId.value, rental)) {
          return true;
        }
      }
      return false;
    }

    return isMatchingCategories(categoryIdToMatch, rental);
  }

  /// Retrieves a list of all rent buildings, including deleted ones.
  static List<RentBuilding> getList() {
    return Data().rentBuildings.iterableList(includeDeleted: true).toList();
  }

  /// Calculates the Profit & Loss (P&L) over the years for a given rental property.
  /// Currently unused and incomplete. Needs further implementation to calculate and store P&L values.
  void getPnLOverYears(RentBuilding rental) {
    for (final Transaction transaction in Data().transactions.iterableList()) {
      if (rental.categoryForIncomeTreeIds.contains(
        transaction.fieldCategoryId.value,
      )) {
        // TODO: Implement P&L calculation logic here
      }
    }
  }

  /// Returns the content for the chart sub-view in the details panel.
  /// Displays either a chart of lifetime P&L for all rentals (if no rental is selected)
  /// or a chart of cumulative profit over time for the selected rental.
  static Widget getSubViewContentForChart({
    required final List<int> selectedIds,
    required final bool showAsNativeCurrency, // Currently unused
  }) {
    if (selectedIds.isEmpty) {
      //
      // UNSELECTED: Chart for all rentals' lifetime P&L
      //
      final List<PairXYY> list = <PairXYY>[];
      for (final RentBuilding entry in getList()) {
        list.add(PairXYY(entry.fieldName.value, entry.lifeTimePnL.profit));
      }
      return Chart(list: list);
    } else {
      //
      // SELECTED: Show cumulated profit over time for the selected rental(s)
      //
      final RentBuilding rental = Data().rentBuildings.get(selectedIds.first) as RentBuilding;

      final List<PairXYY> dataPoints = <PairXYY>[];

      if (!rental.dateRangeOfOperation.hasNullDates) {
        for (int year = rental.dateRangeOfOperation.min!.year; year <= rental.dateRangeOfOperation.max!.year; year++) {
          RentalPnL? pnl = rental.pnlOverYears[year];
          pnl ??= RentalPnL(date: DateTime(year, 1, 1));
          dataPoints.add(PairXYY(year.toString(), pnl.profit, pnl.income));
        }
      }

      return Chart(list: dataPoints);
    }
  }

  /// Returns the content for the P&L sub-view in the details panel.
  /// Displays a message to select a rental if none is selected, otherwise displays
  /// a horizontal scrollable list of yearly and lifetime P&L cards for the selected rental.
  static Widget getSubViewContentForPnL({
    required final List<int> selectedIds,
    required final bool showAsNativeCurrency, // Currently unused
  }) {
    if (selectedIds.isEmpty) {
      return const Text('Select a Rental property to see its P&L');
    }

    // Single Rental property selected
    final RentBuilding rental = Data().rentBuildings.get(selectedIds.first) as RentBuilding;

    // Show PnL for the selected rental property, per year
    final List<Widget> pnlCards = <Widget>[];

    if (!rental.dateRangeOfOperation.hasNullDates) {
      for (int year = rental.dateRangeOfOperation.min!.year; year <= rental.dateRangeOfOperation.max!.year; year++) {
        RentalPnL? pnl = rental.pnlOverYears[year];
        pnl ??= RentalPnL(date: DateTime(year, 1, 1));
        pnlCards.add(RentalPnLCard(pnl: pnl));
      }
    }

    pnlCards.add(
      RentalPnLCard(pnl: rental.lifeTimePnL, customTitle: 'Life Time P&L'),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(children: pnlCards),
    );
  }

  /// Returns the content for the transactions sub-view in the details panel.
  /// Displays a list of transactions associated with the selected rental property.
  static Widget getSubViewContentForTransactions({
    required final List<int> selectedIds,
    required bool showAsNativeCurrency, // Currently unused
  }) {
    final RentBuilding rental = Data().rentBuildings.get(selectedIds.first) as RentBuilding;
    final SelectionController selectionController = Get.put(
      SelectionController(),
    );
    return ListViewTransactions(
      listController: Get.find<ListControllerSidePanel>(),
      columnsToInclude: <Field<dynamic>>[
        Transaction.fields.getFieldByName(columnIdDate),
        Transaction.fields.getFieldByName(columnIdAccount),
        Transaction.fields.getFieldByName(columnIdPayee),
        Transaction.fields.getFieldByName(columnIdCategory),
        Transaction.fields.getFieldByName(columnIdMemo),
        Transaction.fields.getFieldByName(columnIdAmount),
      ],
      getList: () => getTransactionLastSelectedItem(rental),
      selectionController: selectionController,
    );
  }

  /// Retrieves transactions filtered by the provided rental property's categories.
  static List<Transaction> getTransactionLastSelectedItem(
    RentBuilding rentBuildings,
  ) {
    return getTransactions(
      filter: (final Transaction transaction) => filterByRentalCategories(transaction, rentBuildings),
    );
  }

  /// Checks if a given category ID is part of the rental's relevant category trees (income, management, repairs, etc.).
  static bool isMatchingCategories(
    final num categoryIdToMatch,
    final RentBuilding rental,
  ) {
    Data().categories.getTreeIds(rental.categoryForIncome.value);

    return rental.categoryForIncomeTreeIds.contains(categoryIdToMatch) ||
        rental.categoryForManagementTreeIds.contains(categoryIdToMatch) ||
        rental.categoryForRepairsTreeIds.contains(categoryIdToMatch) ||
        rental.categoryForMaintenanceTreeIds.contains(categoryIdToMatch) ||
        rental.categoryForTaxesTreeIds.contains(categoryIdToMatch) ||
        rental.categoryForInterestTreeIds.contains(categoryIdToMatch);
  }
}
