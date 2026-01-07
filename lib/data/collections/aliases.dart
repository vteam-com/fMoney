import 'package:collection/collection.dart';
import 'package:money/data/collections/payees.dart';
import 'package:money/data/entities/alias.dart';
import 'package:money/data/entities/data_abstract.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/models/money_objects.dart';
import 'package:money/models/payee.dart';

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
    return aliasFound?.payeeInstance;
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
