import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/pair_xyz_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/rent_building_entity.dart';
import 'package:money/shared/domain/rental_category_role_enum.dart';
import 'package:money/shared/domain/rental_pnl_model.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/views/panels/cards/rental_pnl_card.dart';
import 'package:money/views/panels/list/transactions_list_view.dart';
import 'package:money/widgets/charts/chart_widget.dart';
import 'package:money/widgets/state/preferences_controller.dart';

/// Contains the logic for the side panel in the View Rentals screen.
class ViewRentalsSidePanel {
  /// Opens Categories view, selecting [categoryId].
  static void openCategoriesForRentalCategory({
    required int categoryId,
  }) {
    if (categoryId < 0) {
      return;
    }

    PreferenceController.to.jumpToView(
      viewId: ViewId.viewCategories,
      selectedId: categoryId,
      textFilter: '',
      columnFilters: null,
    );
  }

  /// Retrieves a list of all rent buildings, including deleted ones.
  static List<RentBuilding> getList() {
    return Data().rentBuildings.iterableList(includeDeleted: true).toList();
  }

  /// Returns the content for the chart sub-view in the details panel.
  /// Displays either a chart of lifetime P&L for all rentals (if no rental is selected)
  /// or a chart of cumulative profit over time for the selected rental.
  static Widget getSubViewContentForChart({
    required List<int> selectedIds,
    required bool showAsNativeCurrency, // Currently unused
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
    required List<int> selectedIds,
    required bool showAsNativeCurrency, // Currently unused
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
        pnlCards.add(
          RentalPnLCard(
            pnl: pnl,
            onCaptionTap: (RentalCategoryRole role) {
              final int categoryId = rental.categoryFieldOf(role).value;
              openCategoriesForRentalCategory(
                categoryId: categoryId,
              );
            },
          ),
        );
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

  /// Retrieves transactions filtered by the provided rental property's categories.
  static List<Transaction> getTransactionLastSelectedItem(
    RentBuilding rentBuildings,
  ) {
    return getTransactions(
      filter: rentBuildings.isTransactionOrSplitAssociatedWithThisRental,
    );
  }
}
