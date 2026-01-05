// ignore_for_file: unnecessary_this

import 'dart:math';

import 'package:money/helpers/investment_types.dart';
import 'package:money/views/data/security.dart';
import 'package:money/views/data/security_sales.dart';

/// This class is used to track the cost basis for a given purchase, sometimes this cost basis
/// has to travel across accounts when a transfer occurs.  When securities are purchased

class SecurityPurchase {
  /// The original cost basis for this security per unit.  THis is not necessarily the
  /// UnitPrice we paid for the security, commissions and fees are also taken into account.

  double costBasisPerUnit = 0;

  /// The date this security was purchased.

  late DateTime datePurchased;

  /// The security that was purchased.

  Security? security;

  /// The number of units remaining from this lot.

  double unitsRemaining = 0;

  double get futuresFactor {
    double factor = 1;
    // futures prices are always listed by the instance.  But wen you buy 1 contract, you always get 100 futures in that contract
    if (security!.fieldSecurityType.value == SecurityType.futures.index) {
      factor = 100;
    }
    return factor;
  }

  /// Get market value of remaining units.

  double? get latestMarketValue {
    return this.futuresFactor * this.unitsRemaining * this.security!.fieldPrice.value.asDouble();
  }

  /// Perform a sale of the given number of units.  If we don't have enough return all that we have.

  /// <param name="date">The date of the sale</param>
  /// <param name="units">The number we'd like to sell</param>
  /// <param name="unitSalePrice">The price per unit we received at date of sale</param>
  /// returns The SecuritySale containing the number of units we are selling from this lot or null
  /// if this lot is empty
  SecuritySale? sell(DateTime date, double units, double unitSalePrice) {
    if (this.unitsRemaining == 0) {
      return null;
    }

    final double canSell = min(units, this.unitsRemaining);

    unitsRemaining -= canSell;

    final SecuritySale s = SecuritySale()
      ..dateSold = date
      ..security = security
      ..costBasisPerUnit = costBasisPerUnit
      ..unitsSold = canSell
      ..dateAcquired = datePurchased
      ..salePricePerUnit = unitSalePrice;

    return s;
  }

  /// The total remaining cost basis based on the number of units remaining.

  double get totalCostBasis {
    return this.costBasisPerUnit * this.unitsRemaining;
  }
}
