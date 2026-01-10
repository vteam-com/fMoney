import 'package:money/data/entities/security.dart';
import 'package:money/data/models/account.dart';

/// This class is used to track the cost basis for a given sale.

class SecuritySale {
  /// The account that it was sold from.

  Account? account;

  /// The original cost basis for this security per unit.  THis is not necessarily the
  /// UnitPrice we paid for the security, commissions and fees are also taken into account.

  double costBasisPerUnit = 0;

  /// The date this security was purchased.

  DateTime? dateAcquired;

  /// The date this security was sold.

  DateTime? dateSold;

  /// This sale represents an error.

  Exception? error;

  /// The price we got for the units at the time of sale (minus fees and commissions)

  double salePricePerUnit = 0;

  /// The security that was purchased.

  Security? security;

  /// The number of units sold

  double unitsSold = 0;

  /// For a roll-up report where individual SecuritySale is too much detail we
  /// can consolidate here, but only if the salePricePerUnit and costBasisPerUnit
  /// match.  If they do not match then we set them to zero so they are reported
  /// as "unknown".

  /// <param name="cg">The other sale to consolidate</param>
  void consolidate(SecuritySale cg) {
    unitsSold += cg.unitsSold;

    if (dateAcquired != cg.dateAcquired) {
      // will be reported to IRS as "VARIOUS"
      dateAcquired = null;
      costBasisPerUnit = 0;
    }
    if (salePricePerUnit != cg.salePricePerUnit) {
      salePricePerUnit = 0;
    }

    if (costBasisPerUnit != cg.costBasisPerUnit) {
      costBasisPerUnit = 0;
    }
  }

  /// The total funds received from the transaction

  double get saleProceeds {
    return salePricePerUnit * unitsSold;
  }

  /// The total remaining cost basis based on the number of units remaining.

  double get totalCostBasis {
    return costBasisPerUnit * unitsSold;
  }

  /// The total difference between the Proceeds and the TotalCostBasis

  double get totalGain {
    return saleProceeds - totalCostBasis;
  }
}
