import 'package:money/helpers/json_helper.dart';
import 'package:money/views/models/money_objects.dart';
import 'package:money/views/models/rental_unit.dart';

class RentUnits extends MoneyObjects<RentUnit> {
  RentUnits() {
    collectionName = 'RentalUnits';
  }

  @override
  RentUnit instanceFromJson(final MyJson json) {
    return RentUnit.fromJson(json);
  }
}
