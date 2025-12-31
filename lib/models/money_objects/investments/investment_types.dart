enum SecurityType {
  none,
  bond, // Bonds
  mutualFund,
  equity, // stocks
  moneyMarket, // cash
  etf, // electronically traded fund
  reit, // Real estate investment trust
  futures, // Futures (a type of commodity investment)
  private, // Investment in a private company.
}

enum InvestmentType {
  // kep this order to avoid changing the index value of each enum
  add, // 0
  remove, // 1
  buy, // 2
  sell, // 3
  none, // 4
  dividend, // 5
}

String getInvestmentTypeText(final InvestmentType type) {
  return type.name.toUpperCase();
}

String getInvestmentTypeTextFromValue(final int value) {
  return getInvestmentTypeText(getInvestmentTypeFromValue(value));
}

InvestmentType getInvestmentTypeFromValue(final int value) {
  return InvestmentType.values[value];
}

InvestmentType getInvestmentTypeFromText(final String name) {
  return InvestmentType.values.byName(name);
}

List<String> getInvestmentTypeNames() {
  return InvestmentType.values.map((InvestmentType item) => item.toString().split('.').last).toList();
}
