import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money/data/collections/transactions.dart';
import 'package:money/data/models/pair_xyz.dart';
import 'package:money/helpers/currency_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/widgets/charts/chart.dart';
import 'package:money/widgets/pure/gaps.dart';
import 'package:money/widgets/pure/icon_button.dart';

/// Widget to display a timeline chart of transactions.
class TransactionTimelineChart extends StatefulWidget {
  const TransactionTimelineChart({super.key, required this.transactions});

  final List<Transaction> transactions;

  @override
  State<TransactionTimelineChart> createState() => _TransactionTimelineChartState();
}

enum TimelineScale { daily, weekly, monthly, yearly }

class _TransactionTimelineChartState extends State<TransactionTimelineChart> {
  TimelineScale _selectedScale = TimelineScale.yearly;

  @override
  Widget build(final BuildContext context) {
    if (widget.transactions.isEmpty) {
      return const Center(child: Text('No transactions'));
    }

    final List<PairXYY> sumByPeriod = _calculateSumByPeriod();

    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            DropdownButton<TimelineScale>(
              value: _selectedScale,
              onChanged: (TimelineScale? newValue) {
                setState(() {
                  _selectedScale = newValue!;
                });
              },
              items: TimelineScale.values.map<DropdownMenuItem<TimelineScale>>((
                TimelineScale value,
              ) {
                return DropdownMenuItem<TimelineScale>(
                  value: value,
                  child: Text(value.name),
                );
              }).toList(),
            ),
            gapMedium(),
            MyIconButton(
              icon: Icons.copy_all_outlined,
              onPressed: () {
                _copyToClipboard(sumByPeriod);
              },
            ),
          ],
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Chart(list: sumByPeriod),
          ),
        ),
      ],
    );
  }

  /// Aggregates transactions into sums by the currently selected [TimelineScale].
  List<PairXYY> _calculateSumByPeriod() {
    switch (_selectedScale) {
      // DAILY
      case TimelineScale.daily:
        return Transactions.transactionSumBy(
          widget.transactions,
          (DateTime date) => dateToString(DateTime(date.year, date.month, date.day)),
        );

      // WEEKLY
      case TimelineScale.weekly:
        return Transactions.transactionSumBy(
          widget.transactions,
          (DateTime date) => dateToString(date.subtract(Duration(days: date.weekday))),
        );

      // MONTHLY
      case TimelineScale.monthly:
        return Transactions.transactionSumBy(
          widget.transactions,
          (DateTime date) => '${date.year}\n${date.month}',
        );

      // YEARLY
      case TimelineScale.yearly:
        return Transactions.transactionSumBy(
          widget.transactions,
          (DateTime date) => date.year.toString(),
        );
    }
  }

  /// Copies the aggregated timeline data to the system clipboard.
  void _copyToClipboard(List<PairXYY> data) {
    final String clipboardData = data
        .map(
          (PairXYY pair) => '${pair.xText} : ${getAmountAsStringUsingCurrency(pair.yValue1)}',
        )
        .join('\n');
    Clipboard.setData(ClipboardData(text: clipboardData));
    // Optional: Show a snackbar to confirm copy
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }
}
