import 'package:fl_chart/fl_chart.dart';
import 'package:money/controller/list_controller.dart';
import 'package:money/controller/selection_controller.dart';
import 'package:money/data/data.dart';
import 'package:money/models/chart_event.dart';
import 'package:money/models/money_objects/categories/category.dart';
import 'package:money/models/money_objects/events/event.dart';
import 'package:money/models/money_objects/transactions/transactions.dart';
import 'package:money/views/dialog/dialog_button.dart';
import 'package:money/views/dialog/dialog_mutate_money_object.dart';
import 'package:money/views/home/sub_views/adaptive_view/adaptive_list/transactions/list_view_transactions.dart';
import 'package:money/views/home/sub_views/view_stocks/stock_chart.dart';
import 'package:money/views/side_panel/side_panel_support.dart';
import 'package:money/widgets_data/charts/my_line_chart.dart';

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
  State<ViewForMoneyObjects> createState() => ViewEventsState();
}

class ViewEventsState extends ViewForMoneyObjectsState {
  ViewEventsState() {
    viewId = ViewId.viewAliases;
  }

  /// add more top level action buttons
  @override
  List<Widget> getActionsButtons(final bool forSidePanelTransactions) {
    final List<Widget> list = super.getActionsButtons(forSidePanelTransactions);
    if (!forSidePanelTransactions) {
      // Add a new Category, place this at the top of the list
      list.insert(
        0,
        buildAddItemButton(() {
          // add a new Event
          final Event newItem = Data().events.addNewEvent();
          updateListAndSelect(newItem.uniqueId);

          // Queue up the edit dialog
          myShowDialogAndActionsForMoneyObject(
            title: 'New ${getClassNameSingular()}',
            moneyObject: newItem,
            onApplyChange: () {
              setState(() {
                /// update
              });
            },
          );
        }, 'Add new event'),
      );
    }
    return list;
  }

  @override
  String getClassNamePlural() {
    return 'Events';
  }

  @override
  String getClassNameSingular() {
    return 'Event';
  }

  /// Returns a human-readable description of the view.
  ///
  /// @return A string describing the purpose of the view.
  @override
  String getDescription() {
    return 'All your major life events';
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
      onTransactions: _getSidePanelViewTransactions,
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
    required final List<int> selectedIds,
    required final bool showAsNativeCurrency,
  }) {
    // get net worth over time
    final List<Transaction> transactionsWithoutTransfers = Data().transactions
        .iterableList(includeDeleted: true)
        .where((Transaction t) => t.isTransfer == false)
        .toList();

    final List<FlSpot> tmpDataPointsWithNetWorth = Transactions.cumulateTransactionPerYearMonth(
      transactionsWithoutTransfers,
    );

    const double marginLeft = 80.0;
    const double marginBottom = 50.0;

    // get the events
    final List<ChartEvent> milestoneTransactions = <ChartEvent>[];

    for (final Event event in getList()) {
      final Category? category = Data().categories.get(
        event.fieldCategoryId.value,
      );
      milestoneTransactions.add(
        ChartEvent(
          dates: DateRange(
            min: event.fieldDateBegin.value!,
            max: event.fieldDateEnd.value ?? DateTime.now(),
          ),
          amount: 0,
          quantity: 1,
          colorBasedOnQuantity: false, // use Amount
          description: event.fieldName.value,
          color: category == null ? Colors.blue : category.getColorOrAncestorsColor(),
        ),
      );
    }

    // sort by ascending date
    milestoneTransactions.sort(
      (ChartEvent a, ChartEvent b) => a.dates.min!.compareTo(b.dates.min!),
    );

    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            left: marginLeft,
            bottom: marginBottom,
          ),
          child: CustomPaint(
            size: const Size(double.infinity, double.infinity),
            painter: PaintActivities(
              activities: milestoneTransactions,
              minX: tmpDataPointsWithNetWorth.first.x,
              maxX: tmpDataPointsWithNetWorth.last.x,
            ),
          ),
        ),
        MyLineChart(dataPoints: tmpDataPointsWithNetWorth, showDots: false),
      ],
    );
  }

  /// Returns a view for displaying the transactions in this view.
  ///
  /// The view is a ListView that displays the transaction fields, including date,
  /// account, category, memo, and amount.
  ///
  /// @param {```List<int>```} selectedIds - A list of IDs of items currently selected.
  /// @param {bool} showAsNativeCurrency - Whether to display the values in native currency format.
  ///
  /// @return The view widget for this view.
  Widget _getSidePanelViewTransactions({
    required final List<int> selectedIds,
    required final bool showAsNativeCurrency,
  }) {
    final SelectionController selectionController = Get.put(
      SelectionController(
        getPreferenceKey(settingKeySidePanel + settingKeySelectedListItemId),
      ),
    );

    return ListViewTransactions(
      listController: Get.find<ListControllerSidePanel>(),
      columnsToInclude: <Field<dynamic>>[
        Transaction.fields.getFieldByName(columnIdDate),
        Transaction.fields.getFieldByName(columnIdAccount),
        Transaction.fields.getFieldByName(columnIdCategory),
        Transaction.fields.getFieldByName(columnIdMemo),
        Transaction.fields.getFieldByName(columnIdAmount),
      ],
      getList: () => getTransactions(
        // filter: (final Transaction transaction) => transaction.fieldDateTime.value == DateTime.now(),
      ),
      selectionController: selectionController,
    );
  }
}
