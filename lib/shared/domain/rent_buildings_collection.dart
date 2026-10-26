import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/shared/domain/rent_building_entity.dart';
import 'package:money/shared/domain/rental_unit_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/widgets/components/rental_pnl_widget.dart';

/// Represents rent buildings.
class RentBuildings extends MoneyObjects<RentBuilding> {
  RentBuildings() {
    collectionName = SharedDomainStrings.domainString117;
  }
  late DataAbstract data;

  @override
  RentBuilding instanceFromJson(MyJson json) {
    return RentBuilding.fromJson(json, data);
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

  /// Accumulates transaction data for a given rental building.
  ///
  /// Iterates through all transactions and uses the `cumulatePnL` method
  /// of the provided `rental` object to aggregate profit and loss data.
  void cumulateTransactions(RentBuilding rental) {
    // Reset the accumulated P&L data for the rental.
    rental.pnlOverYears = <int, RentalPnL>{};

    // Iterate through all transactions in the data store.
    for (Transaction t in data.getTransactions().cast<Transaction>()) {
      // Accumulate P&L for the rental based on the current transaction.
      rental.cumulatePnL(t);
    }
  }
}
