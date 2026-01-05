enum AccountType {
  savings, // 0
  checking, // 1
  moneyMarket, // 2
  cash, // 3
  credit, // 4
  investment, // 5
  retirement, // 6
  notUsed_7, // 7 There is a hole here from deleted type which we can fill when we invent new types, but the types 8-10 have to keep those numbers or else we mess up the existing databases.
  asset, // 8 Used for tracking Assets like "House, Car, Boat, Jewelry, this helps to make NetWorth more accurate
  categoryFund, // 9 a pseudo account for managing category budgets
  loan, // 10
  creditLine, // 11
}
