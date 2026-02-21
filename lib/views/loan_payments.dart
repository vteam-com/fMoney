import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/views/money_objects.dart';
import 'package:money/views/providers/account.dart';
import 'package:money/views/providers/data_abstract.dart';
import 'package:money/views/providers/loan_payment.dart';
import 'package:money/views/providers/transaction.dart';

const int _unsetId = -1;
const int _fakeIdStart = 10000000;
const double _zeroDouble = 0.0;

/// Represents loan payments.
class LoanPayments extends MoneyObjects<LoanPayment> {
  LoanPayments() {
    collectionName = 'LoanPayments';
  }
  late DataAbstract data;

  @override
  void loadFromJson(final List<MyJson> rows) {
    clear();
    for (final MyJson row in rows) {
      appendMoneyObject(LoanPayment.fromJson(row, data));
    }
  }

  @override
  void onAllDataLoaded() {}

  @override
  String toCSV() {
    return MoneyObjects.getCsvFromList(getListSortedById());
  }
}

class _PaymentRollup {
  int accountId = _unsetId;
  late DateTime date;
  double interest = _zeroDouble;
  double principal = _zeroDouble;
  String reference = '';
}

/// Returns loan payments for an account, combining manual entries and matching transactions.
List<LoanPayment> getAccountLoanPayments(Account account, DataAbstract data) {
  final List<int> categoriesToMatch = <int>[
    account.fieldCategoryIdForInterest.value,
    account.fieldCategoryIdForPrincipal.value,
  ];

  // include the manual entries done in the LoanPayments table
  final List<LoanPayment> aggregatedList = data
      .getLoanPayments()
      .cast<LoanPayment>()
      .where((LoanPayment a) => a.fieldAccountId.value == account.uniqueId)
      .toList();

  // include the bank transactions matching the Account Categories for Principal and Interest
  final List<Transaction> listOfTransactions = data
      .getTransactionsFlattenSplits(
        whereClause: (dynamic t) => (t as Transaction).isMatchingAnyOfTheseCategories(categoriesToMatch),
      )
      .cast<Transaction>();

  // Rollup into a single Payment based on Date to match Principal and Interest payment
  final Map<String, _PaymentRollup> payments = <String, _PaymentRollup>{};

  for (final Transaction t in listOfTransactions) {
    // Key is based on date + transaction ID
    final String key = t.dateTimeAsString;

    bool isFromSplit = false;
    _PaymentRollup? pr = payments[key];
    if (pr == null) {
      pr = _PaymentRollup();
      pr.accountId = t.fieldAccountId.value;
      payments[key] = pr;
    } else {
      isFromSplit = true;
    }

    // Date
    pr.date = t.fieldDateTime.value!;

    // Reference (combination of Memo and Payee)
    pr.reference = concat(pr.reference, t.fieldMemo.value, ';', true);
    if (isFromSplit) {
      pr.reference = concat(pr.reference, '<Split>', ';', true);
    }
    pr.reference = concat(
      pr.reference,
      t.getPayeeOrTransferCaption(),
      ';',
      true,
    );

    // Principal
    if (t.fieldCategoryId.value == account.fieldCategoryIdForPrincipal.value) {
      pr.principal += t.fieldAmount.value.asDouble();
    }

    // Interest
    if (t.fieldCategoryId.value == account.fieldCategoryIdForInterest.value) {
      pr.interest += t.fieldAmount.value.asDouble();
    }
  }

  int fakeId = _fakeIdStart;

  for (final _PaymentRollup pr in payments.values) {
    aggregatedList.add(
      LoanPayment(
        id: fakeId++,
        accountId: pr.accountId,
        date: pr.date,
        interest: pr.interest,
        principal: pr.principal,
        memo: '',
        reference: pr.reference,
        data: data,
      ),
    );
  }

  aggregatedList.sort(
    (LoanPayment a, LoanPayment b) => sortByDate(a.fieldDate.value, b.fieldDate.value, true),
  );

  double runningBalance = _zeroDouble;

  for (final LoanPayment p in aggregatedList) {
    runningBalance += p.fieldPrincipal.value.asDouble();
    p.fieldBalance.value.setAmount(runningBalance);

    // Special hack to include the Manual LoanPayment memo into th reference text
    p.fieldReference.value = concat(p.fieldMemo.value, p.fieldReference.value);
  }
  return aggregatedList;
}
