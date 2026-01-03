import 'package:money/widgets_data/money_object/currencies/currency.dart';

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

  String appendDistribution() {
    String text = '';

    distributions.forEach((String name, double percentage) {
      if (name.isNotEmpty) {
        text += textAmount(name, profit * (percentage / 100));
      }
    });
    return text;
  }

  double get expenses => expenseInterest + expenseMaintenance + expenseManagement + expenseRepairs + expenseTaxes;

  double get profit => income + expenses; // since Expense is stored as a negative value we use a [+]

  String textAmount(final String text, final double amount) {
    final String textPadded = '$text:'.padRight(15);
    final String amountPadded = Currency.getAmountAsStringUsingCurrency(
      amount,
      iso4217code: currency,
    ).padLeft(15);
    return '$textPadded\t$amountPadded\n';
  }
}
