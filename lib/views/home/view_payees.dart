import 'package:money/data/models/transaction_types.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/pair_xyz.dart';
import 'package:money/shared/domain/data_domain.dart';
import 'package:money/shared/domain/payee_domain.dart';
import 'package:money/shared/domain/transactions_domain.dart';
import 'package:money/shared/presentation/app_scope.dart';
import 'package:money/shared/presentation/menu_entry.dart';
import 'package:money/views/panels/list_view_transactions.dart';
import 'package:money/views/panels/merge_payees_dialog.dart';
import 'package:money/views/panels/side_panel_support.dart';
import 'package:money/views/panels/transaction_timeline_chart.dart';
import 'package:money/views/panels/view_money_objects.dart';
import 'package:money/widgets/charts/chart.dart';
import 'package:money/widgets/dialogs/button_helpers.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/pure/center_message.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/state/selection_controller.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';

const int _unsetId = -1;
const int _chartMaxItems = 10;

/// Represents view payees.
class ViewPayees extends ViewForMoneyObjects {
  const ViewPayees({super.key});

  @override
  State<ViewForMoneyObjects> createState() => _ViewPayeesState();
}

class _ViewPayeesState extends ViewForMoneyObjectsState {
  _ViewPayeesState() {
    viewId = ViewId.viewPayees;
  }

  /// add more top level action buttons
  @override
  List<Widget> getActionsButtons(final bool forSidePanelTransactions) {
    final List<Widget> list = super.getActionsButtons(forSidePanelTransactions);
    if (!forSidePanelTransactions) {
      /// Merge
      final DataObject? moneyObject = getFirstSelectedItem();
      if (moneyObject != null) {
        list.add(
          buildMergeButton(() {
            // let the user pick another Payee and merge change the transaction of the current selected payee to the destination
            final Payee payee = moneyObject as Payee;
            final Iterable<Transaction> transactions = Data().transactions
                .iterableList(includeDeleted: true)
                .where((Transaction t) => t.fieldPayee.value == payee.uniqueId);
            showMergePayee(context, payee, transactions, Data());
          }),
        );
      }

      // this can go last
      if (getFirstSelectedItem() != null) {
        list.add(
          buildJumpToButton(context, <MenuEntry>[
            MenuEntry(
              icon: ViewId.viewTransactions.getIconData(),
              title: AppL10n.tr(AppTranslationKeys.switchToTransactions),
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
    return AppL10n.tr(AppTranslationKeys.payees);
  }

  @override
  String getClassNameSingular() {
    return AppL10n.tr(AppTranslationKeys.payee);
  }

  @override
  String getDescription() {
    return AppL10n.tr(AppTranslationKeys.whoIsGettingYourMoney);
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
  List<DataObject> getSidePanelTransactions() {
    final Payee? payee = getFirstSelectedItem() as Payee?;
    if (payee != null && payee.fieldId.value > _unsetId) {
      return getTransactions(
        filter: (final Transaction transaction) => transaction.fieldPayee.value == payee.fieldId.value,
      );
    }
    return <DataObject>[];
  }

  /// Details panels Chart panel for Payees
  Widget _getSubViewContentForChart({
    required final List<int> selectedIds,
    required final bool showAsNativeCurrency,
  }) {
    keepUnused(showAsNativeCurrency);
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
        list: listChart.take(_chartMaxItems).toList(),
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
    keepUnused(showAsNativeCurrency);
    final Payee? payee = getMoneyObjectFromFirstSelectedId<Payee>(
      selectedIds,
      list,
    );
    if (payee != null && payee.fieldId.value > _unsetId) {
      final SelectionController selectionController = SelectionController();
      return ListViewTransactions(
        key: Key(payee.uniqueId.toString()),
        listController: AppScope.instance.listControllerSidePanel,
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
