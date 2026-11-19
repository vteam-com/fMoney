import 'package:money/helpers/shared_strings_helper.dart';

/// The category roles of a rental building; each role names a category tree and a P&L total.
enum RentalCategoryRole {
  income(SharedDomainStrings.domainString030),
  interest(SharedDomainStrings.domainString031),
  maintenance(SharedDomainStrings.domainString032),
  management(SharedDomainStrings.domainString033),
  repairs(SharedDomainStrings.domainString034),
  taxes(SharedDomainStrings.domainString035);

  /// Declares a role stored in the RentBuildings column [columnName].
  const RentalCategoryRole(this.columnName);

  /// Name of the RentBuildings column holding the category id of this role.
  final String columnName;

  /// True for the roles whose amounts are expenses, that is every role but [income].
  bool get isExpense => this != income;
}
