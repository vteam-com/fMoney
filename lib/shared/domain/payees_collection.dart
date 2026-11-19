// ignore: fcheck_dead_code
import 'package:collection/collection.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';

/// Represents payees.
class Payees extends MoneyObjects<Payee> with NamedMoneyObjects<Payee> {
  Payees() {
    collectionName = SharedDomainStrings.domainString106;
  }
  late DataAbstract data;

  @override
  void loadFromJson(List<MyJson> rows) {
    clear();
    /*
     */
    for (final MyJson row in rows) {
      final int id = row.getInt(SharedDomainStrings.domainString057, -1);
      final String name = row[SharedDomainStrings.domainString088].toString();
      appendMoneyObject(
        Payee()
          ..fieldId.value = id
          ..fieldName.value = name,
      );
    }
  }

  @override
  String nameOf(Payee item) => item.fieldName.value;

  /// Names a payee id that no payee has, so the dangling reference stays visible.
  @override
  String nameOfMissingId(int id) => '${SharedDomainStrings.domainString162}$id${SharedDomainStrings.domainString163}';

  @override
  void onAllDataLoaded() {
    for (final Payee payee in iterableList()) {
      payee.fieldCount.value = 0;
      payee.fieldSum.value.setAmount(0);
      payee.categories.clear();
    }

    for (final Transaction t in data.getTransactions().cast<Transaction>()) {
      final Payee? item = get(t.fieldPayee.value);
      if (item != null && t.isForPayee(item.uniqueId)) {
        item.fieldCount.value++;
        item.fieldSum.value += t.fieldAmount.value;
        final String categoryName = data.getCategoryNameFromId(t.fieldCategoryId.value).trim();
        if (categoryName.isNotEmpty) {
          item.categories.add(
            data.getCategoryNameFromId(t.fieldCategoryId.value),
          );
        }
      }
    }
  }

  /// Returns sorted payee names as strings.
  List<String> getSortedPayeeNames() {
    return getListSorted().map((Payee p) => p.fieldName.value).toList();
  }

  /// Attempts to find payee wih the given name
  /// if not found create a new payee and return that instance
  Payee getOrCreate(String name, {bool fireNotification = true}) {
    // getByName finds nothing for an empty name, so look for the blank payee here to create it only once
    Payee? payee = name.isEmpty
        ? iterableList().firstWhereOrNull((Payee item) => item.fieldName.value.isEmpty)
        : getByName(name);

    // if not found add new payee
    if (payee == null) {
      payee = Payee();
      payee.fieldId.value = -1;
      payee.fieldName.value = name;
      this.appendNewMoneyObject(
        payee,
        fireNotification: fireNotification,
      );
    }
    return payee;
  }

  /// if not found returns -1
  int getPayeeIdFromName(String name) {
    final Payee? payee = getByName(name);
    if (payee == null) {
      return -1;
    }
    return payee.uniqueId;
  }
}
