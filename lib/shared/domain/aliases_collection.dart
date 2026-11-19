import 'package:collection/collection.dart';
import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';

/// Represents aliases.
class Aliases extends MoneyObjects<Alias> {
  Aliases() {
    collectionName = SharedDomainStrings.domainString016;
  }
  late DataAbstract data;

  @override
  Alias instanceFromJson(MyJson json) {
    return Alias.fromJson(json, data);
  }

  /// Appends a new alias mapping [pattern] (empty for the user to fill in) to [payeeId], and returns it.
  Alias addNewAlias({String pattern = '', AliasType type = AliasType.none, int payeeId = -1}) {
    final Alias alias = Alias(id: -1, pattern: pattern, flags: type.index, payeeId: payeeId, data: data);
    appendNewMoneyObject(alias);
    return alias;
  }

  /// The text an alias made from [transaction] should match: its original bank text, else its payee name.
  static String textOf(Transaction transaction) =>
      transaction.fieldOriginalPayee.value.isEmpty ? transaction.payeeName : transaction.fieldOriginalPayee.value;

  /// The texts of [transaction] an alias is matched against: its original bank text and its payee name.
  static List<String> textsOf(Transaction transaction) => <String>[
    transaction.fieldOriginalPayee.value,
    transaction.payeeName,
  ];

  /// True when [alias] matches [transaction]'s original bank text or its payee name.
  static bool matchesTransaction(Alias alias, Transaction transaction) => textsOf(transaction).any(alias.isMatch);

  /// Returns the aliases that match the original or current payee name of any of [transactions],
  /// or that point at one of their payees.
  List<Alias> relatedTo(Iterable<Transaction> transactions) {
    return iterableList()
        .where(
          (Alias alias) => transactions.any(
            (Transaction t) =>
                (t.fieldPayee.value != -1 && alias.fieldPayeeId.value == t.fieldPayee.value) ||
                matchesTransaction(alias, t),
          ),
        )
        .toList();
  }

  /// Stores on each alias how many aliases share its payee, for the Aliases view.
  void updatePatternCounts() {
    final Map<int, int> countByPayeeId = <int, int>{};
    for (final Alias alias in iterableList()) {
      countByPayeeId[alias.fieldPayeeId.value] = (countByPayeeId[alias.fieldPayeeId.value] ?? 0) + 1;
    }
    for (final Alias alias in iterableList()) {
      alias.fieldPatternCount.value = countByPayeeId[alias.fieldPayeeId.value]!;
    }
  }

  /// Returns one alias per payee from [aliases]: the one whose pattern sorts first.
  static List<Alias> firstPerPayee(Iterable<Alias> aliases) {
    final Map<int, Alias> firstByPayeeId = <int, Alias>{};
    for (final Alias alias in aliases) {
      final Alias? first = firstByPayeeId[alias.fieldPayeeId.value];
      if (first == null || alias.fieldPattern.value.compareTo(first.fieldPattern.value) < 0) {
        firstByPayeeId[alias.fieldPayeeId.value] = alias;
      }
    }
    return firstByPayeeId.values.toList();
  }

  /// Finds a payee by matching the given [text] via aliases.
  Payee? findByMatch(String text) {
    final Alias? aliasFound = iterableList().firstWhereOrNull(
      (Alias item) => item.isMatch(text),
    );
    if (aliasFound == null) {
      return null;
    }
    return data.getPayee(aliasFound.fieldPayeeId.value) as Payee?;
  }

  /// Finds an existing payee by alias match or creates a new one for [text].
  Payee? findOrCreateNewPayee(
    String text, {
    bool fireNotification = true,
  }) {
    Payee? payee = findByMatch(text);
    payee ??= data.getOrCreatePayee(
      text,
      fireNotification: fireNotification,
    ) as Payee?;
    return payee;
  }
}
