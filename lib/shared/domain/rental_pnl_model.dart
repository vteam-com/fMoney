import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/rental_category_role_enum.dart';

const double _percentScale = 100;
const double _zero = 0;
const int _textPaddingWidth = 15;

/// Represents rental pn l.
class RentalPnL {
  RentalPnL({
    required this.date,
    this.currency = SharedStrings.currencyUsd,
    Map<String, double>? distributions,
  }) {
    this.distributions = distributions ?? <String, double>{};
  }

  final DateTime date;

  String currency;
  late Map<String, double> distributions;

  /// Total of each category role; expenses are negative.
  final Map<RentalCategoryRole, double> _amounts = <RentalCategoryRole, double>{};

  @override
  String toString() {
    String text =
        textAmount('Income', income) +
        textAmount('Expenses', expenses) +
        textAmount('  Interest', expenseInterest) +
        textAmount('  Maintenance', expenseMaintenance) +
        textAmount('  Management', expenseManagement) +
        textAmount('  Repairs', expenseRepairs) +
        textAmount('  Taxes', expenseTaxes) +
        textAmount('Profit', profit);

    text += appendDistribution();

    return text;
  }

  /// Appends distribution percentages to the profit text.
  String appendDistribution() {
    String text = '';

    distributions.forEach((String name, double percentage) {
      if (name.isNotEmpty) {
        text += textAmount(name, profit * (percentage / _percentScale));
      }
    });
    return text;
  }

  /// Adds [amount] to the total of [role].
  void add(RentalCategoryRole role, double amount) {
    _amounts[role] = amountOf(role) + amount;
  }

  /// Returns the total of [role].
  double amountOf(RentalCategoryRole role) => _amounts[role] ?? _zero;

  /// Total of the interest expenses.
  double get expenseInterest => amountOf(RentalCategoryRole.interest);

  /// Total of the maintenance expenses.
  double get expenseMaintenance => amountOf(RentalCategoryRole.maintenance);

  /// Total of the management expenses.
  double get expenseManagement => amountOf(RentalCategoryRole.management);

  /// Total of the repair expenses.
  double get expenseRepairs => amountOf(RentalCategoryRole.repairs);

  /// Total of the tax expenses.
  double get expenseTaxes => amountOf(RentalCategoryRole.taxes);

  /// Returns the sum of all expense categories.
  double get expenses => RentalCategoryRole.values
      .where((RentalCategoryRole role) => role.isExpense)
      .fold(_zero, (double sum, RentalCategoryRole role) => sum + amountOf(role));

  /// Total of the incomes.
  double get income => amountOf(RentalCategoryRole.income);

  /// Returns total profit (income + expenses, where expenses are negative).
  double get profit => income + expenses; // since Expense is stored as a negative value we use a [+]

  /// Formats a labeled amount string with padding for column alignment.
  String textAmount(String text, double amount) {
    final String textPadded = '$text:'.padRight(_textPaddingWidth);
    final String amountPadded = getAmountAsStringUsingCurrency(
      amount,
      iso4217code: currency,
    ).padLeft(_textPaddingWidth);
    return '$textPadded${SharedStrings.tab}$amountPadded${SharedStrings.lineFeed}';
  }
}
