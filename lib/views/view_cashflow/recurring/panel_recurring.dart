import 'package:money/helpers/accumulator.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/views/data/data.dart';
import 'package:money/views/data/transactions.dart';
import 'package:money/views/view_cashflow/recurring/recurring_card.dart';
import 'package:money/views/view_cashflow/recurring/recurring_payment.dart';
import 'package:money/widgets/preferences_controller.dart';

class PanelRecurring extends StatefulWidget {
  const PanelRecurring({
    super.key,
    required this.dateRangeSearch,
    required this.minYear,
    required this.maxYear,
    required this.forIncome,
  });

  final DateRange dateRangeSearch;
  final bool forIncome;
  final int maxYear;
  final int minYear;

  @override
  State<PanelRecurring> createState() => _PanelRecurringState();
}

class _PanelRecurringState extends State<PanelRecurring> {
  List<RecurringPayment> recurringPayments = <RecurringPayment>[];

  @override
  void initState() {
    super.initState();
    initRecurringTransactions(forIncome: widget.forIncome);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: getColorTheme(context).surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(21),
        itemCount: recurringPayments.length,
        itemBuilder: (BuildContext context, int index) {
          // build the Card UI
          final RecurringPayment payment = recurringPayments[index];
          return RecurringCard(
            index: index + 1,
            dateRangeSearch: widget.dateRangeSearch,
            dateRangeSelected: DateRange.fromStarEndYears(
              widget.minYear,
              widget.maxYear,
            ),
            payment: payment,
            forIncomeTransaction: widget.forIncome,
          );
        },
      ),
    );
  }

  void findMonthlyRecurringPayments(
    List<Transaction> transactions,
    bool isIncomeTransaction,
  ) {
    // reset the content
    recurringPayments.clear();

    final AccumulatorList<int, Transaction> groupTransactionsByPayeeId = AccumulatorList<int, Transaction>();
    final AccumulatorList<int, int> groupMonthsListByPayeeId = AccumulatorList<int, int>();

    // Step 1: Group transactions by payeeId and record transaction months
    for (final Transaction transaction in transactions.where(
      (final Transaction t) =>
          (isIncomeTransaction && t.fieldAmount.value.asDouble() > 0) ||
          (isIncomeTransaction == false && t.fieldAmount.value.asDouble() <= 0),
    )) {
      final int payeeId = transaction.fieldPayee.value;

      groupTransactionsByPayeeId.cumulate(payeeId, transaction);
      groupMonthsListByPayeeId.cumulate(
        payeeId,
        transaction.fieldDateTime.value!.month,
      );
    }

    // Step 2: Calculate average amount and frequency for each payeeId
    for (final int payeeId in groupMonthsListByPayeeId.getKeys()) {
      final List<int> months = groupMonthsListByPayeeId.getList(payeeId);

      // Check if the frequency indicates monthly recurrence
      if (isMonthlyRecurrence(months)) {
        // keep this payment
        recurringPayments.add(
          RecurringPayment(
            payeeId: payeeId,
            forIncomeTransaction: isIncomeTransaction,
            transactions: groupTransactionsByPayeeId.getList(payeeId),
          ),
        );
      }
    }
  }

  void initRecurringTransactions({required final bool forIncome}) {
    // get all transactions meeting the request of date and type
    bool whereClause(Transaction t) {
      return isBetweenOrEqual(
            t.fieldDateTime.value!.year,
            widget.minYear,
            widget.maxYear,
          ) &&
          ((forIncome == true && t.fieldAmount.value.asDouble() > 0) ||
              (forIncome == false && t.fieldAmount.value.asDouble() < 0));
    }

    final List<Transaction> flatTransactions = Data().transactions.getListFlattenSplits(whereClause: whereClause);

    // get all transaction Income | Expenses
    findMonthlyRecurringPayments(flatTransactions, forIncome);
  }

  bool isMonthlyRecurrence(List<int> months) {
    if (widget.minYear == widget.maxYear) {
      return true;
    }
    // we can conclude that if paid more than 'n' months its a recurring monthly event
    return months.length == PreferenceController.to.cashflowRecurringOccurrences.value;
  }
}
