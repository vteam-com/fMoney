// ignore: fcheck_dead_code
import 'package:collection/collection.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/views/money_objects.dart';
import 'package:money/views/providers/data_abstract.dart';
import 'package:money/views/providers/payee.dart';
import 'package:money/views/providers/transaction.dart';

/// Represents payees.
class Payees extends MoneyObjects<Payee> {
  Payees() {
    collectionName = 'Payees';
  }
  late DataAbstract data;

  @override
  void loadFromJson(final List<MyJson> rows) {
    clear();
    /*
     */
    for (final MyJson row in rows) {
      final int id = row.getInt('Id', -1);
      final String name = row['Name'].toString();
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

  @override
  String toCSV() {
    return MoneyObjects.getCsvFromList(getListSortedById());
  }

  /// Finds a payee by exact name.
  Payee? getByName(final String name) {
    if (name.isEmpty) {
      return null;
    }
    return iterableList().firstWhereOrNull(
      (final Payee payee) => payee.fieldName.value == name,
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
  String getNameFromId(final int id) {
    if (id == -1) {
      return '';
    }

    final Payee? payee = get(id);

    if (payee == null) {
      return '<unknown payee $id>';
    }
    return payee.fieldName.value;
  }

  /// Attempts to find payee wih the given name
  /// if not found create a new payee and return that instance
  Payee getOrCreate(final String name, {bool fireNotification = true}) {
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
  int getPayeeIdFromName(final String name) {
    final Payee? payee = getByName(name);
    if (payee == null) {
      return -1;
    }
    return payee.uniqueId;
  }

  /// Removes payees that have no associated transactions.
  static void removePayeesThatHaveNoTransactions(List<int> payeeIds, DataAbstract data) {
    for (final int payeeId in payeeIds) {
      final Payee? payeeToCheck = data.getPayee(payeeId) as Payee?;
      if (payeeToCheck != null) {
        final Iterable<Transaction> transactions = data.getTransactions().cast<Transaction>();
        final Transaction? matchingTransaction = transactions.firstWhereOrNull(
          (Transaction element) => element.fieldPayee.value == payeeToCheck.uniqueId,
        );
        if (matchingTransaction == null) {
          // No transactions for this payee, we can delete it
          data.deletePayee(payeeToCheck);
        }
      }
    }
  }
}
