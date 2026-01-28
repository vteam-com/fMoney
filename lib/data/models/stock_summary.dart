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

  double get holdingValue => shares * sharePrice;
}
