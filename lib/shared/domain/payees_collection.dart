// ignore: fcheck_dead_code
import 'package:collection/collection.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';

/// Represents payees.
class Payees extends MoneyObjects<Payee> {
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
  void onAllDataLoaded() {
    for (final Payee payee in iterableList()) {
      payee.fieldCount.value = 0;
      payee.fieldSum.value.setAmount(0);
    }

    for (final Transaction t in data.getTransactions().cast<Transaction>()) {
      if (t.isTransfer) {
        // account-to-account: older files may still hold the Transfer category id as payee
        continue;
      }
      final Payee? item = get(t.fieldPayee.value);
      if (item != null) {
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

  /// Finds a payee by name (case-insensitive), like accounts and securities.
  Payee? getByName(String name) {
    if (name.isEmpty) {
      return null;
    }
    return iterableList().firstWhereOrNull(
      (Payee payee) => stringCompareIgnoreCasing(payee.fieldName.value, name) == 0,
    );
  }

  /// Returns a sorted list of all payees by name.
  List<Payee> getListSorted() {
    final List<Payee> list = iterableList().toList();
    list.sort(
      (Payee a, Payee b) => sortByString(a.fieldName.value, b.fieldName.value, true),
    );
    return list;
  }

  /// Returns sorted payee names as strings.
  List<String> getSortedPayeeNames() {
    return getListSorted().map((Payee p) => p.fieldName.value).toList();
  }

  /// Gets the payee name for the given [id]; returns placeholder if not found.
  String getNameFromId(int id) {
    if (id == -1) {
      return '';
    }

    final Payee? payee = get(id);

    if (payee == null) {
      return '${SharedDomainStrings.domainString162}$id${SharedDomainStrings.domainString163}';
    }
    return payee.fieldName.value;
  }

  /// Attempts to find payee wih the given name
  /// if not found create a new payee and return that instance
  Payee getOrCreate(String name, {bool fireNotification = true}) {
    // find or add account of given name
    Payee? payee = getByName(name);

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
