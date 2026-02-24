import 'package:money/helpers/json_helper.dart';
import 'package:money/providers/rental_unit.dart';
import 'package:money/views/money_objects.dart';

/// Represents rent units.
class RentUnits extends MoneyObjects<RentUnit> {
  RentUnits() {
    collectionName = 'RentalUnits';
  }

  @override
  RentUnit instanceFromJson(final MyJson json) {
    return RentUnit.fromJson(json);
  }
}
