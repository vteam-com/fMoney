import 'package:collection/collection.dart';
import 'package:money/data/alias.dart';
import 'package:money/data/data_interface.dart';
import 'package:money/data/payees.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/models/money_objects.dart';
import 'package:money/models/payee.dart';

class Aliases extends MoneyObjects<Alias> {
  Aliases() {
    collectionName = 'Aliases';
  }
  late DataInterface data;

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
    payee ??= (this.data.payees as Payees).getOrCreate(
      text,
      fireNotification: fireNotification,
    );
    return payee;
  }
}
