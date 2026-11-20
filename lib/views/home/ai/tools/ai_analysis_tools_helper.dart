// ignore: fcheck_hardcoded_strings
// Tool names, descriptions and results are written for the AI model, in English; the user never sees them.
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/budget_analyzer_service.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/potential_transfer_match_service.dart';
import 'package:money/shared/domain/reconcile_service.dart';
import 'package:money/shared/domain/rent_building_entity.dart';
import 'package:money/shared/domain/rental_pnl_model.dart';
import 'package:money/shared/domain/similar_payees_helper.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/views/home/ai/tools/ai_data_tools_helper.dart';
import 'package:money/views/home/ai/tools/ai_tool_args_helper.dart';
import 'package:money/views/home/ai/tools/ai_tool_model.dart';
import 'package:money/views/home/ai/tools/ai_transaction_query_model.dart';

/// Argument: a transaction id.
const String _argTransactionId = 'transaction_id';

/// Argument: a payee id.
const String _argPayeeId = 'payee_id';

/// Argument: an account id.
const String _argAccountId = 'account_id';

/// Argument: first year included.
const String _argYearFrom = 'year_from';

/// Argument: last year included.
const String _argYearTo = 'year_to';

/// Argument: part of a building name.
const String _argBuilding = 'building';

/// Argument: one year.
const String _argYear = 'year';

/// Years of history a budget looks at when the model does not say.
const int _defaultBudgetYears = 3;

/// Most categories listed per side of a budget.
const int _maxBudgetCategories = 30;

/// Returns the read-only tools that run the app's own analyses: transfer matching, similar payees,
/// budget, rental profit and loss, and reconciled balances.
List<AiTool> aiAnalysisTools() => <AiTool>[
  AiTool(
    name: 'find_transfer_matches',
    description:
        'Finds transactions in other accounts that look like the other side of a transfer for this '
        'transaction (opposite amount, close date), best match first, using the app\'s transfer matcher.',
    parameters: <String, Map<String, Object>>{_argTransactionId: aiIntParam('Transaction id.')},
    required: <String>[_argTransactionId],
    run: (Map<String, dynamic> args) async => _findTransferMatches(args),
  ),
  AiTool(
    name: 'find_similar_payees',
    description:
        'Lists payees whose names look like the same merchant as this payee and that no alias maps yet: '
        'candidates for merge_payees or create_alias.',
    parameters: <String, Map<String, Object>>{_argPayeeId: aiIntParam('Payee id (from list_payees).')},
    required: <String>[_argPayeeId],
    run: (Map<String, dynamic> args) async => _findSimilarPayees(args),
  ),
  AiTool(
    name: 'budget_recommendation',
    description:
        'Computes a monthly budget from the income and expense history: projected income, recommended '
        'spending, savings rate, and the monthly amount and frequency of the largest categories.',
    parameters: <String, Map<String, Object>>{
      _argYearFrom: aiIntParam('First year of history used; $_defaultBudgetYears years back by default.'),
      _argYearTo: aiIntParam('Last year of history used; this year by default.'),
    },
    run: (Map<String, dynamic> args) async => _budgetRecommendation(args),
  ),
  AiTool(
    name: 'rental_pnl',
    description: 'Returns the profit and loss per year of the rental buildings: income, expenses by kind, profit.',
    parameters: <String, Map<String, Object>>{
      _argBuilding: aiStringParam('Part of the building name; omit for all buildings.'),
      _argYear: aiIntParam('Only this year; omit for every year.'),
    },
    run: (Map<String, dynamic> args) async => _rentalPnl(args),
  ),
  AiTool(
    name: 'reconciled_balance',
    description:
        'Returns an account\'s current balance, its reconciled balance (opening balance plus reconciled '
        'transactions) and the difference still to reconcile.',
    parameters: <String, Map<String, Object>>{_argAccountId: aiIntParam('Account id (from list_accounts).')},
    required: <String>[_argAccountId],
    run: (Map<String, dynamic> args) async => _reconciledBalance(args),
  ),
];

/// Returns [budgets] as rows, largest monthly amount first, capped at [_maxBudgetCategories].
List<Map<String, Object>> _budgetRows(Map<String, BudgetCumulator> budgets) {
  final List<MapEntry<String, BudgetCumulator>> sorted = budgets.entries.toList()
    ..sort(
      (MapEntry<String, BudgetCumulator> a, MapEntry<String, BudgetCumulator> b) =>
          b.value.monthlyAmount.abs().compareTo(a.value.monthlyAmount.abs()),
    );
  return sorted
      .take(_maxBudgetCategories)
      .map(
        (MapEntry<String, BudgetCumulator> entry) => <String, Object>{
          'category': entry.key,
          'monthly': aiRoundToCents(entry.value.monthlyAmount),
          'frequency': entry.value.frequency.name,
        },
      )
      .toList();
}

/// Returns the budget recommendation for the years [args] asks for.
Map<String, Object> _budgetRecommendation(Map<String, dynamic> args) {
  final int thisYear = DateTime.now().year;
  final int yearTo = args.intArg(_argYearTo) ?? thisYear;
  final int yearFrom = args.intArg(_argYearFrom) ?? yearTo - _defaultBudgetYears + 1;
  final List<Transaction> transactions = Data().transactions.getListFlattenSplitsInYearRange(
    minYear: yearFrom,
    maxYear: yearTo,
    where: (Transaction t) => t.isCandidateForBudget,
  );
  if (transactions.isEmpty) {
    return <String, Object>{'note': 'No categorized income or expense from $yearFrom to $yearTo.'};
  }
  final BudgetRecommendation budget = BudgetAnalyzer(transactions).calculateMonthlyBudget();
  return <String, Object>{
    'years': '$yearFrom-$yearTo',
    'projected_monthly_income': aiRoundToCents(budget.projectedIncome),
    'recommended_monthly_expense': aiRoundToCents(budget.recommendedExpense),
    'minimum_monthly_expense': aiRoundToCents(budget.minimumExpense),
    'maximum_monthly_expense': aiRoundToCents(budget.maximumExpense),
    'savings_rate': aiRoundToCents(budget.savingsRate),
    'expense_categories': _budgetRows(budget.categoryBudgetsExpenses),
    'income_categories': _budgetRows(budget.categoryBudgetsIncomes),
  };
}

/// Returns the likely transfer counterparts of the transaction [args] names.
Map<String, Object> _findTransferMatches(Map<String, dynamic> args) {
  final Transaction t = aiTransactionFromArgs(args, _argTransactionId);
  if (!isTransferMatchEligible(t, includeClosedAccounts: true)) {
    return <String, Object>{
      'note': 'Transaction ${t.uniqueId} is already a transfer or is split; it cannot be matched.',
    };
  }
  return <String, Object>{
    'transaction': aiTransactionRow(t),
    'candidates': Data().findPotentialTransferMatches(transaction: t).map(aiTransactionRow).toList(),
  };
}

/// Returns the payees similar to the payee [args] names.
Map<String, Object> _findSimilarPayees(Map<String, dynamic> args) {
  final Payee payee = aiPayeeFromArgs(args, _argPayeeId);
  return <String, Object>{
    'payee': payee.fieldName.value,
    'similar': findSimilarPayees(
      payee,
      Data().payees.iterableList(),
      Data().aliases.iterableList(),
    ).map(aiPayeeRow).toList(),
  };
}

/// Returns the balances of the account [args] names.
Map<String, Object> _reconciledBalance(Map<String, dynamic> args) {
  final Account account = aiItemById(args.intArg(_argAccountId), Data().accounts, 'list_accounts');
  if (!ReconcileService.supportsAccount(account)) {
    return <String, Object>{'note': 'Investment and loan accounts are not reconciled.'};
  }
  final double reconciled = ReconcileService.reconciledBalanceOf(account, Data());
  return <String, Object>{
    'account': account.fieldName.value,
    'balance': aiRoundToCents(account.balance),
    'reconciled_balance': aiRoundToCents(reconciled),
    'not_reconciled': aiRoundToCents(account.balance - reconciled),
  };
}

/// Returns the yearly profit and loss of the buildings and year [args] asks for.
Map<String, Object> _rentalPnl(Map<String, dynamic> args) {
  final String search = args.stringArg(_argBuilding).toLowerCase();
  final int? year = args.intArg(_argYear);
  final List<Map<String, Object>> buildings = Data().rentBuildings
      .iterableList()
      .where((RentBuilding b) => b.fieldName.value.toLowerCase().contains(search))
      .map(
        (RentBuilding b) => <String, Object>{
          'building': b.fieldName.value,
          'years':
              (b.pnlOverYears.entries.where((MapEntry<int, RentalPnL> e) => year == null || e.key == year).toList()
                    ..sort((MapEntry<int, RentalPnL> a, MapEntry<int, RentalPnL> c) => a.key.compareTo(c.key)))
                  .map(
                    (MapEntry<int, RentalPnL> e) => <String, Object>{
                      'year': e.key,
                      'income': aiRoundToCents(e.value.income),
                      'expenses': aiRoundToCents(e.value.expenses),
                      'interest': aiRoundToCents(e.value.expenseInterest),
                      'maintenance': aiRoundToCents(e.value.expenseMaintenance),
                      'management': aiRoundToCents(e.value.expenseManagement),
                      'repairs': aiRoundToCents(e.value.expenseRepairs),
                      'taxes': aiRoundToCents(e.value.expenseTaxes),
                      'profit': aiRoundToCents(e.value.profit),
                    },
                  )
                  .toList(),
        },
      )
      .toList();
  return <String, Object>{'buildings': buildings};
}
