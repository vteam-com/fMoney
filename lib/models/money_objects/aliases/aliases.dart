import 'package:money/data/storage/data/data.dart';
import 'package:money/models/money_objects/aliases/alias.dart';
import 'package:money/models/money_objects/payees/payee.dart';

class Aliases extends MoneyObjects<Alias> {
  Aliases() {
    collectionName = 'Aliases';
  }

  @override
  Alias instanceFromJson(final MyJson json) {
    return Alias.fromJson(json);
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
    payee ??= Data().payees.getOrCreate(
      text,
      fireNotification: fireNotification,
    );
    return payee;
  }
}
