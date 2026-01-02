import 'package:money/data.dart';
import 'package:money/fields/money_objects.dart';
import 'package:money/money_objects/rent_buildings/rent_building.dart';
import 'package:money/money_objects/rent_buildings/rental_pnl.dart';
import 'package:money/money_objects/rental_unit/rental_unit.dart';
import 'package:money/money_objects/transactions/transaction.dart';

class RentBuildings extends MoneyObjects<RentBuilding> {
  RentBuildings() {
    collectionName = 'Rental Buildings';
  }

  @override
  void loadFromJson(final List<MyJson> rows) {
    clear();

    for (final MyJson row in rows) {
      appendMoneyObject(RentBuilding.fromJson(row));
    }
  }

  @override
  void onAllDataLoaded() {
    for (final RentBuilding rental in iterableList(includeDeleted: true)) {
      rental.associateAccountToBuilding();
      cumulateTransactions(rental);

      for (final RentUnit unit in Data().rentUnits.iterableList()) {
        if (unit.fieldBuilding.value == rental.fieldId.value) {
          rental.units.add(unit);
        }
      }
    }
  }

  @override
  String toCSV() {
    return MoneyObjects.getCsvFromList(getListSortedById());
  }

  /// Accumulates transaction data for a given rental building.
  ///
  /// Iterates through all transactions and uses the `cumulatePnL` method
  /// of the provided `rental` object to aggregate profit and loss data.
  void cumulateTransactions(final RentBuilding rental) {
    // Reset the accumulated P&L data for the rental.
    rental.pnlOverYears = <int, RentalPnL>{};

    // Iterate through all transactions in the data store.
    for (Transaction t in Data().transactions.iterableList()) {
      // Accumulate P&L for the rental based on the current transaction.
      rental.cumulatePnL(t);
    }
  }
}
