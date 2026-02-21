// Imports
// The following lines import necessary libraries and packages for the file.
import 'package:money/views/account_aliases.dart';
import 'package:money/views/accounts.dart';
import 'package:money/views/aliases.dart';
import 'package:money/views/categories.dart';
import 'package:money/views/currencies.dart';
import 'package:money/views/events.dart';
import 'package:money/views/investments.dart';
import 'package:money/views/loan_payments.dart';
import 'package:money/views/money_objects.dart';
import 'package:money/views/online_accounts.dart';
import 'package:money/views/payees.dart';
import 'package:money/views/providers/data_abstract.dart';
import 'package:money/views/rent_buildings.dart';
import 'package:money/views/rental_units.dart';
import 'package:money/views/securities.dart';
import 'package:money/views/splits.dart';
import 'package:money/views/stock_splits.dart';
import 'package:money/views/transaction_extras.dart';
import 'package:money/views/transactions.dart';

/// Owns all MoneyObjects managers, their table ordering, and the dependency injection
/// that wires each manager to the active [DataAbstract] implementation.
class DataCollections {
  DataCollections({required DataAbstract data}) {
    tables = <MoneyObjects<dynamic>>[
      accountAliases, // 1
      aliases, // 3
      categories, // 4
      currencies, // 5
      loanPayments, // 7
      onlineAccounts, // 8
      payees, // 9
      transactionExtras, // 15
      transactions, // 16
      // Keep in this order - must come after Transactions
      splits, // 13
      // Keep in this order
      stockSplits, // 14
      investments, // 6 Must be locate after [stockSplits]
      securities, // 12 Must be locate after [investments]

      accounts, // 2
      // Can be last
      rentBuildings, // 10
      rentUnits, // 11
      events,
    ];

    // Inject data interface to managers
    accounts.data = data;
    aliases.data = data;
    categories.data = data;
    payees.data = data;
    investments.data = data;
    loanPayments.data = data;
    securities.data = data;
    rentBuildings.data = data;
    splits.data = data;
    events.data = data;
    transactions.data = data;
    stockSplits.data = data;

    // Note: Some data managers use dependency injection (accounts, aliases, categories, payees, investments, loanPayments, securities, rentBuildings, splits, events, transactions)
    // while others use the global Data() singleton directly for cross-collection access
  }

  late final List<MoneyObjects<dynamic>> tables;

  /// 1 Account Aliases
  final AccountAliases accountAliases = AccountAliases();

  /// 2 Accounts
  final Accounts accounts = Accounts();

  /// 3 Aliases of Payees
  final Aliases aliases = Aliases();

  /// 4 Categories of Transactions
  final Categories categories = Categories();

  /// 5 Currencies definitions used in the money files
  final Currencies currencies = Currencies();

  /// 16 Events
  final Events events = Events();

  /// 6 Investment transactions
  final Investments investments = Investments();

  /// 7
  final LoanPayments loanPayments = LoanPayments();

  /// 8
  final OnlineAccounts onlineAccounts = OnlineAccounts();

  /// 9
  final Payees payees = Payees();

  /// 10
  final RentBuildings rentBuildings = RentBuildings();

  /// 11
  final RentUnits rentUnits = RentUnits();

  /// 12
  final Securities securities = Securities();

  /// 13
  final Splits splits = Splits();

  /// 14
  final StockSplits stockSplits = StockSplits();

  /// 15
  final TransactionExtras transactionExtras = TransactionExtras();

  /// 16 All Transactions in the Money file
  final Transactions transactions = Transactions();
}
