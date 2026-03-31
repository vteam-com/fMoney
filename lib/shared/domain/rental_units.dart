import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:money/shared/domain/money_objects.dart';
import 'package:money/shared/domain/rental_unit.dart';

/// Represents rent units.
class RentUnits extends MoneyObjects<RentUnit> {
  RentUnits() {
    collectionName = SharedDomainStrings.domainString118;
  }

  @override
  RentUnit instanceFromJson(final MyJson json) {
    return RentUnit.fromJson(json);
  }
}
