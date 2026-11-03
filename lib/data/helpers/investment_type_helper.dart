// ignore: fcheck_dead_code
import 'package:money/helpers/list_helper.dart';

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

/// Returns investment type text as uppercase string.
String getInvestmentTypeText(InvestmentType type) {
  return type.name.toUpperCase();
}

/// Returns investment type text from integer value.
String getInvestmentTypeTextFromValue(int value) {
  return getInvestmentTypeText(getInvestmentTypeFromValue(value));
}

/// Returns InvestmentType from integer value.
InvestmentType getInvestmentTypeFromValue(int value) {
  return InvestmentType.values[value];
}

enum InvestmentTradeType {
  none, // 0
  buy, // 1
  buyToOpen, // 2
  buyToCover, // 3,
  buyToClose, // 4,
  sell, // 5
  sellShort, // 6
}

/// Returns investment trade type text as uppercase string.
String getInvestmentTradeTypeText(InvestmentTradeType type) {
  return type.name.toUpperCase();
}

/// Returns InvestmentTradeType from integer value.
InvestmentTradeType getInvestmentTradeTypeFromValue(int value) {
  return InvestmentTradeType.values[value];
}

/// Returns InvestmentTradeType from string name.
InvestmentTradeType getInvestmentTradeTypeFromText(String name) {
  return InvestmentTradeType.values.byName(name);
}

/// Returns list of all investment trade type names.
List<String> getInvestmentTradeTypeNames() {
  return enumToStringList(InvestmentTradeType.values);
}

/// Converts InvestmentType to InvestmentTradeType.
InvestmentTradeType fromInvestmentType(InvestmentType type) {
  switch (type) {
    case InvestmentType.buy:
    case InvestmentType.add:
      return InvestmentTradeType.buy;
    case InvestmentType.sell:
    case InvestmentType.remove:
      return InvestmentTradeType.sell;
    case InvestmentType.dividend:
    case InvestmentType.none:
      return InvestmentTradeType.none;
  }
}
