import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/data/models/pair_xyz_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/shared_strings_domain.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transactions_collection.dart';
import 'package:money/shared/presentation/helpers/menu_entry_model.dart';
import 'package:money/views/panels/charts/transaction_timeline_chart.dart';
import 'package:money/views/panels/dialogs/merge_payees_dialog.dart';
import 'package:money/views/panels/dialogs/similar_payees_dialog.dart';
import 'package:money/views/panels/layout/side_panel_support_model.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/views/panels/list/side_panel_lists_helper.dart';
import 'package:money/views/panels/list/transactions_list_view.dart';
import 'package:money/widgets/charts/chart_widget.dart';
import 'package:money/widgets/dialogs/button_helpers.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';

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
  List<Widget> getActionsButtons(bool forSidePanelTransactions) {
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
                .where((Transaction t) => t.isForPayee(payee.uniqueId));
            showMergePayee(context, payee, transactions, Data());
          }),
        );
        list.add(buildFindSimilarPayeesButton(() => showSimilarPayees(context, moneyObject as Payee)));
      }

      // this can go last
      final Payee? payee = getFirstSelectedItem() as Payee?;
      if (payee != null) {
        list.add(buildJumpToButton(context, <MenuEntry>[MenuEntry.toTransactionsOfPayee(payee: payee)]));
      }
    }
    return list;
  }

  @override
  List<String> get sidePanelTransactionsColumns => sidePanelTransactionsColumnNamesWithoutPayee;

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
      onTransactions: getSidePanelViewTransactions,
    );
  }

  @override
  List<DataObject> getSidePanelTransactions() {
    final Payee? payee = getFirstSelectedItem() as Payee?;
    if (payee != null && payee.fieldId.value > _unsetId) {
      return getTransactions(
        flattenSplits: true,
        filter: (Transaction transaction) => transaction.isForPayee(payee.uniqueId),
      );
    }
    return <DataObject>[];
  }

  /// Details panels Chart panel for Payees
  Widget _getSubViewContentForChart({
    required List<int> selectedIds,
    required bool showAsNativeCurrency,
  }) {
    keepUnused(showAsNativeCurrency);
    if (selectedIds.isEmpty) {
      final List<PairXYY> listChart = <PairXYY>[];
      for (final Payee item in getList()) {
        if (item.fieldName.value != SharedDomainStrings.domainString144) {
          listChart.add(PairXYY(item.fieldName.value, item.fieldCount.value));
        }
      }

      listChart.sort((PairXYY a, PairXYY b) {
        return (b.yValue1.abs() - a.yValue1.abs()).toInt();
      });

      return Chart(
        key: Key(selectedIds.toString()),
        list: listChart.take(_chartMaxItems).toList(),
      );
    }

    final List<Transaction> flatTransactions = Transactions.flatTransactions(
      Data().transactions.iterableList().where(
        (Transaction t) => t.isForPayee(selectedIds.first),
      ),
    );

    return TransactionTimelineChart(transactions: flatTransactions);
  }
}
