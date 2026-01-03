import 'package:collection/collection.dart';
import 'package:money/money_objects/aliases/alias.dart';
import 'package:money/money_objects/payees/payee.dart';
import 'package:money/widgets_data/data/data.dart';
import 'package:money/widgets_data/money_object/money_objects.dart';

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
