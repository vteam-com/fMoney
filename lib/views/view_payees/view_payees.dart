import 'package:get/get.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/helpers/transaction_types.dart';

import 'package:money/views/adaptive_view/view_money_objects.dart';
import 'package:money/views/data/data.dart';
import 'package:money/views/data/domain_buttons.dart';
import 'package:money/views/data/list_view_transactions.dart';
import 'package:money/views/data/menu_entry.dart';
import 'package:money/views/data/merge_payees.dart';
import 'package:money/views/data/payee.dart';
import 'package:money/views/data/transactions.dart';
import 'package:money/views/panels/side_panel/side_panel_support.dart';
import 'package:money/views/panels/transaction_timeline_chart.dart';
import 'package:money/widgets/center_message.dart';
import 'package:money/widgets/charts/chart.dart';
import 'package:money/widgets/dialog_button.dart';
import 'package:money/widgets/preferences_controller.dart';
import 'package:money/widgets/selection_controller.dart';
import 'package:money/widgets/widgets_domain/cd/field.dart';
import 'package:money/widgets/widgets_domain/cd/money_object.dart';

class ViewPayees extends ViewForMoneyObjects {
  const ViewPayees({super.key});

  @override
  State<ViewForMoneyObjects> createState() => ViewPayeesState();
}

class ViewPayeesState extends ViewForMoneyObjectsState {
  ViewPayeesState() {
    viewId = ViewId.viewPayees;
  }

  /// add more top level action buttons
  @override
  List<Widget> getActionsButtons(final bool forSidePanelTransactions) {
    final List<Widget> list = super.getActionsButtons(forSidePanelTransactions);
    if (!forSidePanelTransactions) {
      /// Merge
      final MoneyObject? moneyObject = getFirstSelectedItem();
      if (moneyObject != null) {
        list.add(
          buildMergeButton(() {
            // let the user pick another Payee and merge change the transaction of the current selected payee to the destination
            final Payee payee = moneyObject as Payee;
            showMergePayee(context, payee);
          }),
        );
      }

      // this can go last
      if (getFirstSelectedItem() != null) {
        list.add(
          buildJumpToButton(context, <MenuEntry>[
            MenuEntry(
              icon: ViewId.viewTransactions.getIconData(),
              title: 'Switch to Transactions',
              onPressed: () {
                final Payee? payee = getFirstSelectedItem() as Payee?;
                if (payee != null) {
                  // Prepare the Transaction view to show only the selected account
                  switchViewTransactionForPayee(payee.fieldName.value);
                }
              },
            ),
          ]),
        );
      }
    }
    return list;
  }

  @override
  String getClassNamePlural() {
    return 'Payees';
  }

  @override
  String getClassNameSingular() {
    return 'Payee';
  }

  @override
  String getDescription() {
    return 'Who is getting your money.';
  }

  @override
  Fields<Payee> getFieldsForTable() {
    return Payee.fieldsForColumnView;
  }

  @override
  List<Payee> getList({bool includeDeleted = false, bool applyFilter = true}) {
    final List<Payee> list = Data().payees
        .iterableList(includeDeleted: includeDeleted)
        .where(
          (Payee instance) => applyFilter == false || isMatchingFilters(instance),
        )
        .toList();

    return list;
  }

  @override
  SidePanelSupport getSidePanelSupport() {
    return SidePanelSupport(
      onDetails: getSidePanelViewDetails,
      onChart: _getSubViewContentForChart,
      onTransactions: _getSubViewContentForTransactions,
    );
  }

  @override
  List<MoneyObject> getSidePanelTransactions() {
    final Payee? payee = getFirstSelectedItem() as Payee?;
    if (payee != null && payee.fieldId.value > -1) {
      return getTransactions(
        filter: (final Transaction transaction) => transaction.fieldPayee.value == payee.fieldId.value,
      );
    }
    return <MoneyObject>[];
  }

  /// Details panels Chart panel for Payees
  Widget _getSubViewContentForChart({
    required final List<int> selectedIds,
    required final bool showAsNativeCurrency,
  }) {
    if (selectedIds.isEmpty) {
      final List<PairXYY> listChart = <PairXYY>[];
      for (final Payee item in getList()) {
        if (item.fieldName.value != 'Transfer') {
          listChart.add(PairXYY(item.fieldName.value, item.fieldCount.value));
        }
      }

      listChart.sort((final PairXYY a, final PairXYY b) {
        return (b.yValue1.abs() - a.yValue1.abs()).toInt();
      });

      return Chart(
        key: Key(selectedIds.toString()),
        list: listChart.take(10).toList(),
      );
    }

    final List<Transaction> flatTransactions = Transactions.flatTransactions(
      Data().transactions.iterableList().where(
        (Transaction t) => t.fieldPayee.value == selectedIds.first,
      ),
    );

    return TransactionTimelineChart(transactions: flatTransactions);
  }

  // Details Panel for Transactions Payees
  Widget _getSubViewContentForTransactions({
    required final List<int> selectedIds,
    required bool showAsNativeCurrency,
  }) {
    final Payee? payee = getMoneyObjectFromFirstSelectedId<Payee>(
      selectedIds,
      list,
    );
    if (payee != null && payee.fieldId.value > -1) {
      final SelectionController selectionController = Get.put(
        SelectionController(),
      );
      return ListViewTransactions(
        key: Key(payee.uniqueId.toString()),
        listController: Get.find<ListControllerSidePanel>(),
        columnsToInclude: <Field<dynamic>>[
          Transaction.fields.getFieldByName(columnIdDate),
          Transaction.fields.getFieldByName(columnIdAccount),
          Transaction.fields.getFieldByName(columnIdCategory),
          Transaction.fields.getFieldByName(columnIdMemo),
          Transaction.fields.getFieldByName(columnIdAmount),
        ],
        getList: () => getTransactions(
          flattenSplits: true,
          filter: (final Transaction transaction) => transaction.fieldPayee.value == payee.fieldId.value,
        ),
        selectionController: selectionController,
      );
    }
    return CenterMessage.noTransaction();
  }
}
