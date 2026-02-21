import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/pairs.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/views/data.dart';
import 'package:money/widgets/columns/column_header_button.dart';
import 'package:money/widgets/my_banner.dart';
import 'package:money/widgets/pure/box.dart';
import 'package:money/widgets/pure/gaps.dart';
import 'package:money/widgets/semantic_text.dart';
import 'package:money/widgets/value_parser.dart';
import 'package:money/widgets/value_quality.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const int _columnFlexDate = 1;
const int _columnFlexDescription = 2;
const int _columnFlexAmount = 1;
const int _defaultSortColumnIndex = 0;

/// A stateful widget for import transactions list preview.
class ImportTransactionsListPreview extends StatefulWidget {
  const ImportTransactionsListPreview({
    super.key,
    required this.accountId,
    required this.values,
  });

  final int accountId;
  final List<ValuesQuality> values;

  @override
  State<ImportTransactionsListPreview> createState() => _ImportTransactionsListPreviewState();
}

class _ImportTransactionsListPreviewState extends State<ImportTransactionsListPreview> {
  late final List<Triple<String, TextAlign, int>> _columnNames = <Triple<String, TextAlign, int>>[
    Triple<String, TextAlign, int>('Date', TextAlign.left, _columnFlexDate),
    Triple<String, TextAlign, int>('Description/Payee', TextAlign.left, _columnFlexDescription),
    Triple<String, TextAlign, int>('Amount', TextAlign.right, _columnFlexAmount),
  ];

  bool _sortAscending = true;

  /// 0=Date, 1=Memo, 2=Amount
  int _sortColumnIndex = _defaultSortColumnIndex;

  @override
  void initState() {
    super.initState();
    ValuesParser.evaluateExistence(
      accountId: widget.accountId,
      values: widget.values,
      transactionExistsCallback:
          ({
            required int accountId,
            required DateTime dateTime,
            required double amount,
          }) =>
              null !=
              Data().transactions.findExistingTransaction(
                accountId: accountId,
                dateRange: DateRange(min: dateTime.startOfDay, max: dateTime.endOfDay),
                amount: amount,
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.values.isEmpty) {
      return Box(
        title: 'Preview',
        padding: SizeForPadding.huge,
        child: buildWarning(context, 'No transactions'),
      );
    }

    _sortValues();

    return Box(
      header: buildHeaderTitleAndCounter(
        context,
        'Preview',
        buildTallyOfItemsToImportOrSkip(),
      ),
      copyToClipboard: () {
        final String text = widget.values.toList().join('\n');
        copyToClipboardAndInformUser(context, text);
      },
      child: Column(
        children: <Widget>[
          //
          // header
          //
          _buildColumnHeaders(context),

          //
          // list
          //
          Expanded(
            child: ListView.separated(
              separatorBuilder: (BuildContext _, int _) => const Divider(),
              itemCount: widget.values.length,
              itemBuilder: (BuildContext _, int index) => _buildTransactionRow(widget.values[index]),
            ),
          ),

          //
          // Footer
          //
          Container(
            color: getColorTheme(context).surfaceContainerLow,
            padding: const EdgeInsets.all(SizeForPadding.small),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text(
                  ValuesQuality.getDateRange(widget.values).toStringDays(),
                  style: const TextStyle(fontSize: SizeForText.small),
                ),
                const Spacer(),
                const Text(
                  'Total',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: SizeForText.small),
                ),
                gapSmall(),
                WidgetFromData(
                  amountModel: AmountModel(
                    amount: sumOfValues(),
                    iso4217: widget.values.first.amount.currency,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds tally string showing items to import vs total items.
  String buildTallyOfItemsToImportOrSkip() {
    final int totalItems = widget.values.length;
    final int itemsToImport = widget.values.where((ValuesQuality item) => !item.exist).length;
    String text = getIntAsText(widget.values.length);
    if (totalItems != itemsToImport) {
      text = '${getIntAsText(itemsToImport)}/${getIntAsText(totalItems)}';
    }
    return '$text entries';
  }

  /// Returns sum of all values in the list.
  double sumOfValues() {
    double sum = 0;
    for (final ValuesQuality value in widget.values) {
      sum += value.amount.asAmount();
    }
    return sum;
  }

  /// Builds the header row for the preview table, including sort indicator.
  Widget _buildColumnHeaders(BuildContext context) {
    return Container(
      color: getColorTheme(context).surfaceContainerLow,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List<Widget>.generate(
          _columnNames.length,
          (int index) => buildColumnHeaderButton(
            context: context,
            text: _columnNames[index].first,
            textAlign: _columnNames[index].second,
            flex: _columnNames[index].third,
            sortIndicator: getSortIndicator(
              _sortColumnIndex,
              index,
              _sortAscending,
            ),
            hasFilters: false,
            onPressed: () => _updateSortChoice(index),
            onLongPress: null,
          ),
        ),
      ),
    );
  }

  /// Builds the description/payee cell and shows a badge if it matches an existing payee.
  Widget _buildDescriptionOrPayee(
    BuildContext context,
    ValueQuality valueQuality,
  ) {
    final String payeeName = valueQuality.valueAsString;
    final bool payeeMatch = Data().payees.getByName(payeeName) != null;

    return Row(
      children: <Widget>[
        Expanded(child: valueQuality.valueAsTextWidget(context)),
        if (payeeMatch)
          const Badge(
            label: Text('Payee Match'),
            backgroundColor: Colors.lightBlue,
            textColor: Colors.black,
          ),
      ],
    );
  }

  /// Builds a single preview row for an imported transaction.
  Widget _buildTransactionRow(ValuesQuality value) {
    final Widget dateAsWidget = value.date.valueAsDateWidget(context);
    final Widget payeeAsWidget = _buildDescriptionOrPayee(
      context,
      value.description,
    );
    final Widget amountAsWidget = value.amount.valueAsAmountWidget(context);

    return MyBanner(
      on: value.exist,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(flex: _columnFlexDate, child: dateAsWidget),
          Expanded(flex: _columnFlexDescription, child: payeeAsWidget),
          Expanded(flex: _columnFlexAmount, child: amountAsWidget),
        ],
      ),
    );
  }

  void _sortValues() {
    ValuesQuality.sort(widget.values, _sortColumnIndex, _sortAscending);
  }

  /// Updates the sort selection and re-sorts the preview list.
  void _updateSortChoice(int columnIndex) {
    setState(() {
      if (columnIndex == _sortColumnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
      }
      _sortValues();
    });
  }
}
