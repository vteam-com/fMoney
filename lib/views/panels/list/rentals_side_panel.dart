import 'package:flutter/material.dart';
import 'package:money/data/helpers/transaction_type_helper.dart';
import 'package:money/data/models/pair_xyz_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/rent_building_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/views/panels/cards/rental_pnl_card.dart';
import 'package:money/views/panels/list/transactions_list_view.dart';
import 'package:money/widgets/charts/chart_widget.dart';
import 'package:money/widgets/components/rental_pnl_widget.dart';
import 'package:money/widgets/state/selection_controller.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';

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
      for (final TransactionSplit split in t.splits) {
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

  /// Returns the content for the chart sub-view in the details panel.
  /// Displays either a chart of lifetime P&L for all rentals (if no rental is selected)
  /// or a chart of cumulative profit over time for the selected rental.
  static Widget getSubViewContentForChart({
    required final List<int> selectedIds,
    required final bool showAsNativeCurrency, // Currently unused
  }) {
    keepUnused(showAsNativeCurrency);
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
      final RentBuilding? rental = Data().rentBuildings.get(selectedIds.first);
      if (rental == null) {
        return Center(child: Text(AppL10n.tr(AppTranslationKeys.rentalPropertyNotFound)));
      }

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
    keepUnused(showAsNativeCurrency);
    if (selectedIds.isEmpty) {
      return Text(AppL10n.tr(AppTranslationKeys.selectARentalPropertyToSeeItsPL));
    }

    // Single Rental property selected
    final RentBuilding? rental = Data().rentBuildings.get(selectedIds.first);
    if (rental == null) {
      return Center(child: Text(AppL10n.tr(AppTranslationKeys.rentalPropertyNotFound)));
    }

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
      RentalPnLCard(
        pnl: rental.lifeTimePnL,
        customTitle: AppL10n.tr(AppTranslationKeys.lifeTimePnl),
      ),
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
    keepUnused(showAsNativeCurrency);
    final RentBuilding? rental = Data().rentBuildings.get(selectedIds.first);
    if (rental == null) {
      return Center(child: Text(AppL10n.tr(AppTranslationKeys.rentalPropertyNotFound)));
    }
    final SelectionController selectionController = SelectionController();
    return ListViewTransactions(
      listController: AppScope.instance.listControllerSidePanel,
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
