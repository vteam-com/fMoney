import 'package:money/data/entities/data_abstract.dart';
import 'package:money/data/entities/rent_building.dart';
import 'package:money/data/entities/transaction.dart';
import 'package:money/data/models/rental_unit.dart';
import 'package:money/data/money_objects.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/widgets/rental_pnl.dart';

class RentBuildings extends MoneyObjects<RentBuilding> {
  RentBuildings() {
    collectionName = 'Rental Buildings';
  }
  late DataAbstract data;

  @override
  void loadFromJson(final List<MyJson> rows) {
    clear();

    for (final MyJson row in rows) {
      appendMoneyObject(RentBuilding.fromJson(row, data));
    }
  }

  @override
  void onAllDataLoaded() {
    for (final RentBuilding rental in iterableList(includeDeleted: true)) {
      rental.associateAccountToBuilding();
      cumulateTransactions(rental);

      for (final RentUnit unit in (data.getRentUnits() as MoneyObjects<RentUnit>).iterableList()) {
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
    for (Transaction t in data.getTransactions().cast<Transaction>()) {
      // Accumulate P&L for the rental based on the current transaction.
      rental.cumulatePnL(t);
    }
  }
}
