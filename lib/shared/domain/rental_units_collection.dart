import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/shared/domain/rental_unit_entity.dart';

/// Represents rent units.
class RentUnits extends MoneyObjects<RentUnit> {
  RentUnits() {
    collectionName = SharedDomainStrings.domainString118;
  }

  @override
  RentUnit instanceFromJson(MyJson json) {
    return RentUnit.fromJson(json);
  }
}
