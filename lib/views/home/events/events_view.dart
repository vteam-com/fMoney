import 'package:fl_chart/fl_chart.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/event_entity.dart';
import 'package:money/shared/domain/transactions_collection.dart';
import 'package:money/views/panels/charts/net_worth_chart.dart';
import 'package:money/views/panels/charts/stock_chart.dart';
import 'package:money/views/panels/layout/side_panel_support_model.dart';
import 'package:money/views/panels/list/add_new_item_button_mixin.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/views/panels/list/side_panel_lists_helper.dart';
import 'package:money/views/panels/list/transactions_list_view.dart';
import 'package:money/widgets/charts/my_line_chart.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';

/// ViewForMoneyObjects class with ViewEvents as a subclass.
class ViewEvents extends ViewForMoneyObjects {
  /// Constructor for the ViewEvents class.
  ///
  /// @param {super.key} - Initializes the key of the superclass.
  const ViewEvents({super.key});

  @override
  /// Creates and returns a new instance of the State class associated with this view.
  ///
  /// @return A new instance of the State class.
  State<ViewForMoneyObjects> createState() => _ViewEventsState();
}

class _ViewEventsState extends ViewForMoneyObjectsState with AddNewItemButtonMixin {
  _ViewEventsState() {
    viewId = ViewId.viewEvents;
  }

  @override
  String get addNewItemTooltip => AppL10n.tr(AppTranslationKeys.addNewEvent);

  @override
  DataObject createNewItem() => Data().events.addNewEvent();

  @override
  List<String> get sidePanelTransactionsColumns => sidePanelTransactionsColumnNamesWithoutPayee;

  @override
  String getClassNamePlural() {
    return AppL10n.tr(AppTranslationKeys.events);
  }

  @override
  String getClassNameSingular() {
    return AppL10n.tr(AppTranslationKeys.event);
  }

  /// Returns a human-readable description of the view.
  ///
  /// @return A string describing the purpose of the view.
  @override
  String getDescription() {
    return AppL10n.tr(AppTranslationKeys.allYourMajorLifeEventsDescription);
  }

  /// Defines the fields for the table that displays the data in this view.
  ///
  /// @return A list of Fields representing the columns to display.
  @override
  Fields<Event> getFieldsForTable() {
    return Event.fieldsForColumnView;
  }

  /// Returns a list of Events that match the current filters and includeDeleted flags.
  ///
  /// @param {bool} includeDeleted - Whether to include deleted Events in the list.
  /// @param {bool} applyFilter - Whether to apply any filters before returning the list.
  /// @return A list of Events matching the specified conditions.
  @override
  List<Event> getList({bool includeDeleted = false, bool applyFilter = true}) {
    return Data().events
        .iterableList(includeDeleted: includeDeleted)
        .where(
          (Event instance) => applyFilter == false || isMatchingFilters(instance),
        )
        .toList();
  }

  /// Returns the SidePanelSupport instance associated with this view.
  ///
  /// @return The SidePanelSupport instance.
  @override
  SidePanelSupport getSidePanelSupport() {
    return SidePanelSupport(
      onDetails: getSidePanelViewDetails,
      onChart: _getSidePanelViewChart,
      onTransactions: getSidePanelViewTransactions,
    );
  }

  /// Returns a chart for displaying the data in this view.
  ///
  /// The chart shows net worth over time. It includes milestone transactions,
  /// which are Events that have a significant impact on the net worth (i.e., amount).
  ///
  /// @param {```List<int>```} selectedIds - A list of IDs of items currently selected.
  /// @param {bool} showAsNativeCurrency - Whether to display the values in native currency format.
  ///
  /// @return The chart widget for this view.
  Widget _getSidePanelViewChart({
    required List<int> selectedIds,
    required bool showAsNativeCurrency,
  }) {
    keepUnused(selectedIds, showAsNativeCurrency);
    // get net worth over time
    final List<Transaction> transactionsWithoutTransfers = Data().transactions
        .iterableList(includeDeleted: true)
        .where((Transaction t) => t.isTransfer == false)
        .toList();

    final List<FlSpot> tmpDataPointsWithNetWorth = Transactions.cumulateTransactionPerYearMonth(
      transactionsWithoutTransfers,
      Data(),
    );

    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        if (tmpDataPointsWithNetWorth.isNotEmpty)
          lineChartOverlay(
            PaintActivities(
              activities: chartEventsFromEvents(getList()),
              minX: tmpDataPointsWithNetWorth.first.x,
              maxX: tmpDataPointsWithNetWorth.last.x,
            ),
          ),
        MyLineChart(dataPoints: tmpDataPointsWithNetWorth, showDots: false),
      ],
    );
  }

  @override
  List<DataObject> getSidePanelTransactions() {
    return getTransactions(
      // filter: (final Transaction transaction) => transaction.fieldDateTime.value == DateTime.now(),
    );
  }
}
