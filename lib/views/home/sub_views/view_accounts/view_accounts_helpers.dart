part of 'view_accounts.dart';

extension ViewAccountsHelpers on ViewAccountsState {
  /// Calculates the total balance of the specified account types.
  ///
  /// This function iterates over the active accounts of the specified [types] and
  /// sums up the normalized balance values of each account. The normalized
  /// balance is obtained by calling `x.fieldBalanceNormalized.getValueForDisplay(x)`.
  ///
  /// @param types The list of account types to include in the total balance.
  /// @return The total balance of the specified account types.
  double getTotalBalanceOfAccounts(final List<AccountType> types) {
    double total = 0.0;
    Data().accounts
        .activeAccounts(types)
        .forEach(
          (final Account x) => total += (x.fieldBalanceNormalized.getValueForDisplay(x) as MoneyModel).asDouble(),
        );
    return total;
  }

  /// Filters a [Transaction] by the specified [accountId].
  ///
  /// This function checks if the [fieldAccountId] value of the given [Transaction]
  /// matches the provided [accountId].
  ///
  /// @param t The [Transaction] to filter.
  /// @param accountId The account ID to filter by.
  /// @return `true` if the [Transaction]'s [fieldAccountId] matches the provided [accountId], `false` otherwise.
  bool filterByAccountId(final Transaction t, final num accountId) {
    return t.fieldAccountId.value == accountId;
  }

  List<AccountType> getSelectedAccountType() {
    if (_selectedPivot[0]) {
      return getSelectedAccountTypesByIndex(0);
    }

    if (_selectedPivot[1]) {
      return getSelectedAccountTypesByIndex(1);
    }

    if (_selectedPivot[2]) {
      return getSelectedAccountTypesByIndex(2);
    }

    if (_selectedPivot[3]) {
      return getSelectedAccountTypesByIndex(3);
    }

    return getSelectedAccountTypesByIndex(-1);
  }

  /// Returns a list of [AccountType] based on the provided [index].
  ///
  /// This function is used to get the appropriate list of account types based on the
  /// selected pivot in the UI. The returned list of account types is used to filter
  /// the accounts displayed in the view.
  ///
  /// @param index The index of the selected pivot. Valid values are 0, 1, 2, 3, and -1 (for "all" account types).
  /// @return A list of [AccountType] corresponding to the provided [index].
  List<AccountType> getSelectedAccountTypesByIndex(final int index) {
    switch (index) {
      case 0:
        return <AccountType>[AccountType.checking, AccountType.savings];

      case 1:
        return <AccountType>[AccountType.investment, AccountType.retirement];

      case 2:
        return <AccountType>[AccountType.credit, AccountType.creditLine];

      case 3:
        return <AccountType>[
          AccountType.asset,
          AccountType.cash,
          AccountType.loan,
        ];

      default: // all
        return <AccountType>[];
    }
  }

  Widget _renderToggles() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
      child: ToggleButtons(
        key: const Key('view_accounts_pivots'),
        direction: Axis.horizontal,
        onPressed: (final int index) {
          // ignore: invalid_use_of_protected_member
          setState(() {
            for (int i = 0; i < _selectedPivot.length; i++) {
              _selectedPivot[i] = i == index;
            }
            list = getList();
            clearSelection();
          });
        },
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        constraints: const BoxConstraints(minHeight: 40.0, minWidth: 100.0),
        isSelected: _selectedPivot,
        children: _pivots,
      ),
    );
  }
}
