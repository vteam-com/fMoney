import 'package:money/core/controller/data_controller.dart';
import 'package:money/core/controller/selection_controller.dart';
import 'package:money/core/helpers/accumulator.dart';
import 'package:money/core/widgets/box.dart';
import 'package:money/core/widgets/dialog/dialog_button.dart';
import 'package:money/core/widgets/dialog/dialog_mutate_money_object.dart';
import 'package:money/core/widgets/gaps.dart';
import 'package:money/core/widgets/label_and_amount.dart';
import 'package:money/core/widgets/side_panel/side_panel.dart';
import 'package:money/core/widgets/side_panel/side_panel_views_enum.dart';
import 'package:money/core/widgets/snack_bar.dart';
import 'package:money/core/widgets/text_title.dart';
import 'package:money/data/models/fields/field_filters.dart';
import 'package:money/data/models/money_objects/accounts/account.dart';
import 'package:money/data/models/money_objects/accounts/account_types_enum.dart';
import 'package:money/data/models/money_objects/accounts/accounts.dart';
import 'package:money/data/models/money_objects/currencies/currency.dart';
import 'package:money/data/models/money_objects/investments/investment_types.dart';
import 'package:money/data/models/money_objects/investments/investments.dart';
import 'package:money/data/models/money_objects/loan_payments/loan_payments.dart';
import 'package:money/data/models/money_objects/securities/security.dart';
import 'package:money/data/models/money_objects/transactions/transaction.dart';
import 'package:money/data/storage/data/data.dart';
import 'package:money/data/storage/get_stock_from_cache_or_backend.dart';
import 'package:money/data/storage/import/import_investment.dart';
import 'package:money/data/storage/import/import_investment_panel.dart';
import 'package:money/data/storage/import/import_wizard.dart';
import 'package:money/views/home/sub_views/adaptive_view/adaptive_list/adaptive_columns_or_rows_list.dart';
import 'package:money/views/home/sub_views/adaptive_view/adaptive_list/adaptive_columns_or_rows_single_selection.dart';
import 'package:money/views/home/sub_views/adaptive_view/adaptive_list/transactions/list_view_transactions.dart';
import 'package:money/views/home/sub_views/money_object_card.dart';

part 'view_accounts_side_panel.dart';
part 'view_accounts_helpers.dart';

/// Main view for all Accounts
class ViewAccounts extends ViewForMoneyObjects {
  const ViewAccounts({super.key, super.includeClosedAccount});

  @override
  State<ViewForMoneyObjects> createState() => ViewAccountsState();
}

class ViewAccountsState extends ViewForMoneyObjectsState {
  ViewAccountsState() {
    viewId = ViewId.viewAccounts;
  }

  final List<Widget> _pivots = <Widget>[];

  // Footer related
  final DateRange _footerColumnDate = DateRange();

  // Filter related
  final List<bool> _selectedPivot = <bool>[false, false, false, false, true];

  @override
  Widget buildHeader([final Widget? child]) {
    return super.buildHeader(_renderToggles());
  }

  @override
  void didUpdateWidget(ViewAccounts oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle changes in widget properties
    if (oldWidget.includeClosedAccount != widget.includeClosedAccount) {
      list = getList();
    }
  }

  @override
  List<Widget> getActionsButtons(final bool forSidePanelTransactions) {
    final List<Widget> list = super.getActionsButtons(forSidePanelTransactions);

    if (forSidePanelTransactions) {
      list.add(
        buildJumpToButton(<MenuEntry>[
          MenuEntry(
            icon: ViewId.viewTransactions.getIconData(),
            title: 'Matching Transaction',
            onPressed: () {
              final Transaction? selectedInfoTransaction = getSidePanelLastSelectedTransaction();

              if (selectedInfoTransaction != null) {
                // Look for transaction matching -1 to +1 date from this transaction
                final DateRange approximationDates = DateRange(
                  min: selectedInfoTransaction.fieldDateTime.value!.add(const Duration(days: -1)).startOfDay,
                  max: selectedInfoTransaction.fieldDateTime.value!.add(const Duration(days: 1)).endOfDay,
                );
                // we are looking for the reverse transaction
                final double amountToFind = selectedInfoTransaction.fieldAmount.value.asDouble() * -1;

                final Transaction? matchingTransaction = Data().transactions.findExistingTransaction(
                  accountId: -1,
                  dateRange: approximationDates,
                  amount: amountToFind,
                );
                // Switch view
                if (matchingTransaction != null) {
                  PreferenceController.to.jumpToView(
                    viewId: ViewId.viewTransactions,
                    selectedId: matchingTransaction.uniqueId,
                    textFilter: '',
                    columnFilters: null,
                  );
                  return;
                }
              }
              SnackBarService.displayWarning(
                message: 'No matching transactions',
              );
            },
          ),
        ]),
      );
    } else {
      // Place this in front off all the other actions button
      list.insert(
        0,
        buildAddItemButton(() {
          // add a new Account
          final Account newItem = Data().accounts.addNewAccount(
            'New Bank Account',
          );
          updateListAndSelect(newItem.uniqueId);
        }, 'Add new account'),
      );

      // this can go last
      final Account? account = getFirstSelectedItem() as Account?;
      if (account != null) {
        list.add(
          buildJumpToButton(<MenuEntry>[
            MenuEntry.toTransactions(
              transactionId: -1,
              // Prepare the Transaction view Filter to show only the selected account
              filters: FieldFilters(<FieldFilter>[
                FieldFilter(
                  fieldName: Constants.viewTransactionFieldNameAccount,
                  strings: <String>[account.fieldName.value],
                ),
              ]),
            ),
            MenuEntry.toInvestments(accountName: account.fieldName.value),
          ]),
        );
      }
    }

    return list;
  }

  @override
  String getClassNamePlural() {
    return 'Accounts';
  }

  @override
  String getClassNameSingular() {
    return 'Account';
  }

  // default currency for this view
  @override
  List<String> getCurrencyChoices(
    final SidePanelSubViewEnum subViewId,
    final List<int> selectedItems,
  ) {
    switch (subViewId) {
      case SidePanelSubViewEnum.chart: // Chart
      case SidePanelSubViewEnum.transactions: // Transactions
        final Account? account = getFirstSelectedItemFromSelectedList(selectedItems) as Account?;
        if (account != null) {
          if (account.fieldCurrency.value != Constants.defaultCurrency) {
            // only offer currency toggle if the account is not USD based
            return <String>[
              account.fieldCurrency.value,
              Constants.defaultCurrency,
            ];
          }
        }

        return <String>[Constants.defaultCurrency];
      default:
        return <String>[];
    }
  }

  @override
  String getDescription() {
    return 'Your main assets.';
  }

  @override
  Fields<Account> getFieldsForTable() {
    return Account.fieldsForColumnView;
  }

  @override
  List<Account> getList({
    bool includeDeleted = false,
    bool applyFilter = true,
  }) {
    List<Account> list = Data().accounts.activeAccount(
      getSelectedAccountType(),
      isActive: PreferenceController.to.includeClosedAccounts ? null : true,
    );

    if (applyFilter) {
      list = list.where((final Account instance) => isMatchingFilters(instance)).toList();
    } else {
      list = list.toList();
    }

    _footerColumnDate.clear();

    for (final Account account in list) {
      _footerColumnDate.inflate(account.fieldUpdatedOn.value);
    }
    return list;
  }

  @override
  SidePanelSupport getSidePanelSupport() {
    return SidePanelSupport(
      onDetails: _getSidePanelViewDetails,
      onChart: _getSubViewContentForChart,
      onTransactions: _getSidePanelViewTransactions,
    );
  }

  @override
  List<MoneyObject> getSidePanelTransactions() {
    final Account? account = getFirstSelectedItem() as Account?;
    if (account != null) {
      return getTransactionForLastSelectedAccount(account);
    }
    return <MoneyObject>[];
  }

  @override
  void initState() {
    super.initState();

    onAddTransaction = () {
      showImportTransactionsWizard();
    };

    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_bank'),
        text1: 'Banks',
        small: true,
        isVertical: true,
        text2: Currency.getAmountAsStringUsingCurrency(
          getTotalBalanceOfAccounts(getSelectedAccountTypesByIndex(0)),
        ),
      ),
    );
    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_investment'),
        text1: 'Investments',
        small: true,
        isVertical: true,
        text2: Currency.getAmountAsStringUsingCurrency(
          getTotalBalanceOfAccounts(getSelectedAccountTypesByIndex(1)),
        ),
      ),
    );
    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_credit'),
        text1: 'Credit',
        small: true,
        isVertical: true,
        text2: Currency.getAmountAsStringUsingCurrency(
          getTotalBalanceOfAccounts(getSelectedAccountTypesByIndex(2)),
        ),
      ),
    );
    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_assets'),
        text1: 'Assets',
        small: true,
        isVertical: true,
        text2: Currency.getAmountAsStringUsingCurrency(
          getTotalBalanceOfAccounts(getSelectedAccountTypesByIndex(3)),
        ),
      ),
    );
    _pivots.add(
      ThreePartLabel(
        key: const Key('key_toggle_show_all'),
        text1: 'All',
        small: true,
        isVertical: true,
        text2: Currency.getAmountAsStringUsingCurrency(
          getTotalBalanceOfAccounts(getSelectedAccountTypesByIndex(-1)),
        ),
      ),
    );
  }
}
