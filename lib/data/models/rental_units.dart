import 'package:money/data/abstract/money_objects.dart';
import 'package:money/data/models/rental_unit.dart';
import 'package:money/helpers/json_helper.dart';

class RentUnits extends MoneyObjects<RentUnit> {
  RentUnits() {
    collectionName = 'RentalUnits';
  }

  @override
  RentUnit instanceFromJson(final MyJson json) {
    return RentUnit.fromJson(json);
  }
}
