import 'package:money/helpers/ranges.dart';

class StockCumulative {
  double amount = 0.00;
  DateRange dateRange = DateRange();
  List<Dividend> dividends = <Dividend>[];
  double dividendsSum = 0.00;
  double quantity = 0.0;
}

class Dividend {
  Dividend(this.date, this.amount);

  final double amount;
  final DateTime date;
}
