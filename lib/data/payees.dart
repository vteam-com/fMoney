import 'package:collection/collection.dart';
import 'package:money/data/data_interface.dart';
import 'package:money/data/transaction.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/models/money_objects.dart';
import 'package:money/models/payee.dart';
import 'package:money/widgets/mutation_types.dart';

class Payees extends MoneyObjects<Payee> {
  Payees() {
    collectionName = 'Payees';
  }
  late DataInterface data;

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

    for (Transaction t in data.transactions.iterableList() as Iterable<Transaction>) {
      final Payee? item = get(t.fieldPayee.value);
      if (item != null) {
        item.fieldCount.value++;
        item.fieldSum.value += t.fieldAmount.value;
        final String categoryName = (data.categories.getNameFromId(t.fieldCategoryId.value) as String).trim();
        if (categoryName.isNotEmpty) {
          item.categories.add(
            data.categories.getNameFromId(t.fieldCategoryId.value) as String,
          );
        }
      }
    }
  }

  @override
  String toCSV() {
    return MoneyObjects.getCsvFromList(getListSortedById());
  }

  Payee? getByName(final String name) {
    if (name.isEmpty) {
      return null;
    }
    return iterableList().firstWhereOrNull(
      (final Payee payee) => payee.fieldName.value == name,
    );
  }

  List<Payee> getListSorted() {
    final List<Payee> list = iterableList().toList();
    list.sort(
      (Payee a, Payee b) => sortByString(a.fieldName.value, b.fieldName.value, true),
    );
    return list;
  }

  List<String> getSortedPayeeNames() {
    return getListSorted().map((Payee p) => p.fieldName.value).toList();
  }

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
      data.payees.appendNewMoneyObject(
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

  static void removePayeesThatHaveNoTransactions(List<int> payeeIds, DataInterface data) {
    for (final int payeeId in payeeIds) {
      final Payee? payeeToCheck = data.payees.get(payeeId) as Payee?;
      if (payeeToCheck != null) {
        final Iterable<Transaction> transactions = data.transactions.iterableList() as Iterable<Transaction>;
        if (transactions.firstWhereOrNull(
              (Transaction element) => element.fieldPayee.value == payeeToCheck.uniqueId,
            ) ==
            null) {
          // No transactions for this payee, we can delete it
          data.payees.deleteItem(payeeToCheck);
        }
      }
    }
  }
}

void mutateTransactionsToPayee(
  final List<Transaction> transactions,
  final int toPayeeId,
  final int? categoryId,
  final DataInterface data,
) {
  final Set<int> fromPayeeIds = <int>{};

  for (final Transaction t in transactions) {
    // keep track of the payeeIds that we remove transactions from
    fromPayeeIds.add(t.fieldPayee.value);

    t.stashValueBeforeEditing();
    t.stashOriginalPayee();

    t.fieldPayee.value = toPayeeId;
    if (categoryId != null) {
      t.fieldCategoryId.value = categoryId;
    }

    data.notifyMutationChanged(
      mutation: MutationType.changed,
      moneyObject: t,
      recalculateBalances: false,
    );
  }
  Payees.removePayeesThatHaveNoTransactions(fromPayeeIds.toList(), data);
  data.updateAll();
}
