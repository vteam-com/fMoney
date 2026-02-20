import 'package:money/data/models/dividend.dart';
import 'package:money/helpers/ranges.dart';

export 'package:money/data/models/dividend.dart';

/// Represents stock cumulative.
class StockCumulative {
  double amount = 0.00;
  DateRange dateRange = DateRange();
  List<Dividend> dividends = <Dividend>[];
  double dividendsSum = 0.00;
  double quantity = 0.0;
}
