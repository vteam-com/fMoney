import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/data/models/pair_xyz_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/investment_entity.dart';
import 'package:money/shared/domain/transactions_collection.dart';
import 'package:money/shared/presentation/helpers/menu_entry_model.dart';
import 'package:money/shared/presentation/widgets/money_object_card_widget.dart';
import 'package:money/shared/presentation/widgets/transaction_splits_list_view_widget.dart';
import 'package:money/views/home/transactions/transaction_actions_helper.dart';
import 'package:money/views/panels/cards/transfer_sender_receiver_card.dart';
import 'package:money/views/panels/layout/side_panel_support_model.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/views/panels/list/transaction_aliases_panel.dart';
import 'package:money/widgets/charts/chart_widget.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/pure/center_message_widget.dart';

const double _zeroDouble = 0.0;

/// ViewTransactions is a widget that displays a list of financial transactions.
///
/// This widget extends [ViewForMoneyObjects] and is responsible for rendering
/// a view of transactions with various features such as filtering, sorting,
/// and displaying transaction details.
///
/// Key features:
/// - Displays a list of transactions with customizable views
/// - Supports multi-selection of transactions
/// - Calculates and displays running balances for transactions
/// - Allows navigation to related views (e.g., Accounts, Categories)
///
/// The [startingBalance] parameter can be used to set an initial balance
/// for the transaction list.

class ViewTransactions extends ViewForMoneyObjects {
  const ViewTransactions({super.key, this.startingBalance = _zeroDouble});

  final double startingBalance;

  @override
  State<ViewForMoneyObjects> createState() => _ViewTransactionsState();
}

class _ViewTransactionsState extends ViewForMoneyObjectsState {
  _ViewTransactionsState() {
    viewId = ViewId.viewTransactions;
    supportsMultiSelection = true;
    onItemContextMenu = (BuildContext context, int _, Offset position) =>
        showTransactionActionsMenu(context, position, _selectedTransactions());
  }

  /// Adds the transaction action shortcuts (edit, change category or payee, create alias, similar payees).
  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: transactionActionShortcuts(context, _selectedTransactions),
      child: super.build(context),
    );
  }

  /// Returns the transactions selected in the main list.
  List<Transaction> _selectedTransactions() => _transactionsOf(selectedIds);

  /// Returns the main list's transactions with [ids].
  List<Transaction> _transactionsOf(List<int> ids) =>
      getSelectedItemsFromSelectedList(ids).whereType<Transaction>().toList();

  bool balanceDone = false;

  @override
  List<Widget> getActionsButtons(bool forSidePanelTransactions) {
    final List<Widget> list = super.getActionsButtons(forSidePanelTransactions);

    final Transaction? transaction = getFirstSelectedItem() as Transaction?;
    if (!forSidePanelTransactions && transaction != null) {
      final Category? category = Data().categories.get(transaction.fieldCategoryId.value);

      // this can go last
      list.add(
        buildJumpToButton(context, <MenuEntry>[
          MenuEntry.toAccounts(accountId: transaction.fieldAccountId.value),
          if (category != null) MenuEntry.toCategory(category: category),
          MenuEntry.toPayee(payeeId: transaction.fieldPayee.value),
          // Search Payee
          MenuEntry(
            icon: Icons.person_search_outlined,
            title: AppL10n.tr(AppTranslationKeys.searchForPayee),
            onPressed: () => launchGoogleSearch(transaction.getPayeeOrTransferCaption()),
          ),
        ]),
      );
    }

    return list;
  }

  @override
  String getClassNamePlural() {
    return AppL10n.tr(AppTranslationKeys.transactions);
  }

  @override
  String getClassNameSingular() {
    return AppL10n.tr(AppTranslationKeys.transaction);
  }

  @override
  String getDescription() {
    return AppL10n.tr(AppTranslationKeys.transactionsDescription);
  }

  @override
  Fields<DataObject> getFieldsForTable() {
    return Transaction.fieldsForColumnView as Fields<DataObject>;
  }

  @override
  List<Transaction> getList({
    bool includeDeleted = false,
    bool applyFilter = true,
  }) {
    final List<Transaction> list = Data().transactions
        .iterableList(includeDeleted: includeDeleted)
        .where(
          (Transaction transaction) => applyFilter == false || isMatchingFilters(transaction),
        )
        .toList();

    if (!balanceDone) {
      Transactions.applyRunningBalance(list);
      balanceDone = true;
    }
    return list;
  }

  @override
  SidePanelSupport getSidePanelSupport() {
    return SidePanelSupport(
      onDetails: getSidePanelViewDetails,
      onChart: _getSidePanelViewChart,
      onTransactions: _getSidePanelViewTransactions,
      onAliases: _getSidePanelViewAliases,
    );
  }

  /// Builds the side panel list of aliases related to the selected transactions.
  Widget _getSidePanelViewAliases({required List<int> selectedIds}) {
    final List<Transaction> transactions = _transactionsOf(selectedIds);
    if (transactions.isEmpty) {
      return CenterMessage.noTransaction();
    }
    return TransactionAliasesPanel(key: Key(selectedIds.join(',')), transactions: transactions);
  }

  /// Builds the side panel chart subview showing totals per top-level category.
  Widget _getSidePanelViewChart({
    required List<int> selectedIds,
    required bool showAsNativeCurrency,
  }) {
    keepUnused(selectedIds, showAsNativeCurrency);
    final Map<String, num> tallyPerCategory = <String, num>{};

    getList().forEach((Transaction transaction) {
      final num value = transaction.fieldAmount.value.asDouble();
      final int categoryId = transaction.fieldCategoryId.value;
      Category? category = Data().categories.get(categoryId);
      category ??= Data().categories.unknown;
      final Category parentCategory = Data().categories.getTopAncestor(
        category,
      );

      // Update the map or add a new entry
      tallyPerCategory.update(
        parentCategory.name,
        (num total) => total + value,
        ifAbsent: () => value,
      );
    });

    final List<PairXYY> list = <PairXYY>[];
    tallyPerCategory.forEach((String key, num value) {
      list.add(PairXYY(key, value));
    });

    list.sort(
      (PairXYY a, PairXYY b) => a.yValue1.compareTo(b.yValue1),
    );

    return Chart(list: list);
  }

  /// Builds the side panel transactions subview showing related details for the selection.
  Widget _getSidePanelViewTransactions({
    required List<int> selectedIds,
    required bool showAsNativeCurrency,
  }) {
    keepUnused(selectedIds, showAsNativeCurrency);
    final Transaction? transaction = getFirstSelectedItem() as Transaction?;

    //
    // If the category of this transaction is a Split then list the details of the Split
    //
    if (transaction != null) {
      if (transaction.isSplit) {
        // this is Split get the split transactions
        return ListViewTransactionSplits(
          key: Key('split_transactions ${transaction.uniqueId}'),
          splits: transaction.splits,
          totalAmount: transaction.fieldAmount.value.asDouble(),
        );
      }

      if (transaction.isTransfer) {
        if (transaction.instanceOfTransfer == null) {
          return Text(AppL10n.tr(AppTranslationKeys.missingTransfer));
        }
        return TransferSenderReceiver(
          transfer: transaction.instanceOfTransfer!,
        );
      } else {
        final Investment? investment = Data().investments.get(
          transaction.uniqueId,
        );
        if (investment != null) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: MoneyObjectCard(
              title: AppL10n.tr(AppTranslationKeys.investment),
              moneyObject: investment,
            ),
          );
        }
      }
    }
    return CenterMessage(message: AppL10n.tr(AppTranslationKeys.noRelatedTransactions));
  }
}
