import 'package:money/helpers/json_helper.dart';
import 'package:money/models/rental_unit/rental_unit.dart';
import 'package:money/widgets/money_objects.dart';

class RentUnits extends MoneyObjects<RentUnit> {
  RentUnits() {
    collectionName = 'RentalUnits';
  }

  @override
  RentUnit instanceFromJson(final MyJson json) {
    return RentUnit.fromJson(json);
  }
}
