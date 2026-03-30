import 'package:money/helpers/investment_types.dart';
import 'package:money/shared/domain/account.dart';
import 'package:money/shared/domain/category.dart';

/// Represents investment import fields.
class InvestmentImportFields {
  InvestmentImportFields({
    required this.account,
    required this.date,
    required this.investmentType,
    required this.category,
    required this.symbol,
    required this.units,
    required this.amountPerUnit,
    required this.transactionAmount,
    required this.description,
  });

  Account account;
  double amountPerUnit;
  Category category;
  DateTime date;
  String description;
  InvestmentType investmentType;
  String symbol;
  double transactionAmount;
  double units;
}
