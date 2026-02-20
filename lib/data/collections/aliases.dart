import 'package:collection/collection.dart';
import 'package:money/data/entities/alias.dart';
import 'package:money/data/entities/data_abstract.dart';
import 'package:money/data/models/payee.dart';
import 'package:money/data/money_objects.dart';
import 'package:money/helpers/json_helper.dart';

/// Represents aliases.
class Aliases extends MoneyObjects<Alias> {
  Aliases() {
    collectionName = 'Aliases';
  }
  late DataAbstract data;

  @override
  Alias instanceFromJson(final MyJson json) {
    return Alias.fromJson(json, data);
  }

  @override
  String toCSV() {
    return MoneyObjects.getCsvFromList(getListSortedById());
  }

  Payee? findByMatch(final String text) {
    final Alias? aliasFound = iterableList().firstWhereOrNull(
      (final Alias item) => item.isMatch(text),
    );
    if (aliasFound == null) {
      return null;
    }
    return data.getPayee(aliasFound.fieldPayeeId.value) as Payee?;
  }

  Payee? findOrCreateNewPayee(
    final String text, {
    bool fireNotification = true,
  }) {
    Payee? payee = findByMatch(text);
    payee ??=
        data.getOrCreatePayee(
              text,
              fireNotification: fireNotification,
            )
            as Payee?;
    return payee;
  }
}
