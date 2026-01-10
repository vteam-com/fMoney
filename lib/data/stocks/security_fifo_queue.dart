// ignore_for_file: unnecessary_this

import 'package:money/data/entities/security.dart';
import 'package:money/data/models/account.dart';
import 'package:money/data/stocks/security_purchase.dart';
import 'package:money/data/stocks/security_sales.dart';

/// We implement a first-in first-out FIFO queue for securities, the assumption is that when
/// securities are sold you will first sell the security you have been holding the longest
/// in order to minimize capital gains taxes.

class SecurityFifoQueue {
  /// The account the security is held in.
  Account? account;

  List<SecurityPurchase> list = <SecurityPurchase>[];

  /// list of pending sales that we couldn't cover before, we keep these until the matching Buy arrives.
  List<SecuritySale> pending = <SecuritySale>[];

  /// The security that we are tracking with this queue.
  Security? security;

  /// Record an Add or Buy for a given security.
  /// <param name="datePurchased">The date of the purchase</param>
  /// <param name="units">The number of units purchased</param>
  /// <param name="amount">The total cost basis for this purchase</param>
  void buy(DateTime datePurchased, double units, double costBasis) {
    final SecurityPurchase sp = SecurityPurchase();
    sp.security = security;
    sp.datePurchased = datePurchased;
    sp.costBasisPerUnit = costBasis / units;
    sp.unitsRemaining = units;

    // insert the purchase in date order
    for (int i = 0, n = this.list.length; i < n; i++) {
      final SecurityPurchase e = this.list[i];
      if (e.datePurchased.millisecond > datePurchased.millisecond) {
        this.list.insert(i, sp);
        return;
      }
    }

    this.list.add(sp);
  }

  List<SecurityPurchase> getHoldings() {
    final List<SecurityPurchase> result = <SecurityPurchase>[];
    for (SecurityPurchase sp in this.list) {
      if (sp.unitsRemaining > 0) {
        result.add(sp);
      }
    }
    return result;
  }

  List<SecuritySale> getPendingSales() {
    return this.pending;
  }

  List<SecuritySale> processPendingSales() {
    // now that more has arrived, time to see if we can process those pending sales.
    final List<SecuritySale> copy = List<SecuritySale>.from(this.pending);
    this.pending.clear();
    final List<SecuritySale> result = <SecuritySale>[];
    for (final SecuritySale s in copy) {
      // this will put any remainder back in the pending list if it still can't be covered.
      for (SecuritySale real in this.sell(
        s.dateSold!,
        s.unitsSold,
        s.unitsSold * s.salePricePerUnit,
      )) {
        result.add(real);
      }
    }
    return result;
  }

  /// Find the oldest holdings that still have UnitsRemaining, and decrement them by the
  /// number of units we are selling.  This might have to sell from multiple SecurityPurchases
  /// in order to cover the requested number of units.  If there are not enough units to cover
  /// the sale then we have a problem and we return a SecuritySale containing the Error information.

  /// <param name="dateSold">The date of the sale</param>
  /// <param name="units">The number of units sold</param>
  /// <param name="amount">The total amount we received from the sale</param>
  List<SecuritySale> sell(DateTime dateSold, double units, double amount) {
    final double salePricePerUnit = amount / units;
    final List<SecuritySale> result = <SecuritySale>[];
    for (SecurityPurchase purchase in this.list) {
      final SecuritySale? sale = purchase.sell(
        dateSold,
        units,
        salePricePerUnit,
      );
      if (sale != null) {
        sale.account = account;
        units -= sale.unitsSold;
        result.add(sale);

        if (units <= 0) {
          break; // done!
        }
      }
    }

    if (units.floor() > 0) {
      // Generate an error item so we can report this problem later.
      final SecuritySale ss = SecuritySale();
      ss.security = security;
      ss.account = account;
      ss.dateSold = dateSold;
      ss.unitsSold = units;
      ss.salePricePerUnit = salePricePerUnit;

      this.pending.add(ss);
    }
    return result;
  }
}
