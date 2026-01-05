import 'package:collection/collection.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/views/data/data.dart';
import 'package:money/views/models/aliases/alias.dart';
import 'package:money/views/models/payees/payee.dart';
import 'package:money/widgets/money_objects.dart';

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
