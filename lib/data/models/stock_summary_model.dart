/// Represents stock summary.
class StockSummary {
  StockSummary({
    required this.symbol,
    required this.shares,
    required this.sharePrice,
    required this.averageCost,
  });

  final double averageCost;
  final double sharePrice;
  final double shares;
  final String symbol;

  /// Returns the current holding value (shares multiplied by share price).
  double get holdingValue => shares * sharePrice;
}
