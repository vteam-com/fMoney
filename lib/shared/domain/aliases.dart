import 'package:collection/collection.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:money/shared/domain/alias.dart';
import 'package:money/shared/domain/data_abstract.dart';
import 'package:money/shared/domain/money_objects.dart';
import 'package:money/shared/domain/payee.dart';

/// Represents aliases.
class Aliases extends MoneyObjects<Alias> {
  Aliases() {
    collectionName = SharedDomainStrings.domainString016;
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

  /// Finds a payee by matching the given [text] via aliases.
  Payee? findByMatch(final String text) {
    final Alias? aliasFound = iterableList().firstWhereOrNull(
      (final Alias item) => item.isMatch(text),
    );
    if (aliasFound == null) {
      return null;
    }
    return data.getPayee(aliasFound.fieldPayeeId.value) as Payee?;
  }

  /// Finds an existing payee by alias match or creates a new one for [text].
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
