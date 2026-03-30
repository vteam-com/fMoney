import 'package:money/helpers/currency_helper.dart';

const double _percentScale = 100;
const int _textPaddingWidth = 15;

/// Represents rental pn l.
class RentalPnL {
  RentalPnL({
    required this.date,
    this.income = 0,
    this.expenseInterest = 0,
    this.expenseMaintenance = 0,
    this.expenseManagement = 0,
    this.expenseRepairs = 0,
    this.expenseTaxes = 0,
    this.currency = 'USD',
    Map<String, double>? distributions,
  }) {
    this.distributions = distributions ?? <String, double>{};
  }

  final DateTime date;

  String currency;
  late Map<String, double> distributions;
  double expenseInterest;
  double expenseMaintenance;
  double expenseManagement;
  double expenseRepairs;
  double expenseTaxes;
  double income;

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

  /// Returns the sum of all expense categories.
  double get expenses => expenseInterest + expenseMaintenance + expenseManagement + expenseRepairs + expenseTaxes;

  /// Returns total profit (income + expenses, where expenses are negative).
  double get profit => income + expenses; // since Expense is stored as a negative value we use a [+]

  /// Formats a labeled amount string with padding for column alignment.
  String textAmount(final String text, final double amount) {
    final String textPadded = '$text:'.padRight(_textPaddingWidth);
    final String amountPadded = getAmountAsStringUsingCurrency(
      amount,
      iso4217code: currency,
    ).padLeft(_textPaddingWidth);
    return '$textPadded\t$amountPadded\n';
  }
}
