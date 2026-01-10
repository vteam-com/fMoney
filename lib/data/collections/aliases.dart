import 'package:collection/collection.dart';
import 'package:money/data/abstract/money_objects.dart';
import 'package:money/data/collections/payees.dart';
import 'package:money/data/entities/alias.dart';
import 'package:money/data/entities/data_abstract.dart';
import 'package:money/data/models/payee.dart';
import 'package:money/helpers/json_helper.dart';

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
    return (this.data.payees as Payees).get(aliasFound.fieldPayeeId.value);
  }

  Payee? findOrCreateNewPayee(
    final String text, {
    bool fireNotification = true,
  }) {
    Payee? payee = findByMatch(text);
    payee ??= (this.data.payees as Payees).getOrCreate(
      text,
      fireNotification: fireNotification,
    );
    return payee;
  }
}
