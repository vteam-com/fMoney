import 'package:money/data/data.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/pairs.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/widgets/box.dart';
import 'package:money/widgets/columns/column_header_button.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/my_banner.dart';
import 'package:money/widgets/semantic_text.dart';
import 'package:money/widgets_data/money_model.dart';
import 'package:money/widgets_data/money_widget.dart';
import 'package:money/widgets_data/value_parser.dart';

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
    Triple<String, TextAlign, int>('Date', TextAlign.left, 1),
    Triple<String, TextAlign, int>('Description/Payee', TextAlign.left, 2),
    Triple<String, TextAlign, int>('Amount', TextAlign.right, 1),
  ];

  bool _sortAscending = true;

  /// 0=Date, 1=Memo, 2=Amount
  int _sortColumnIndex = 0;

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
              separatorBuilder: (BuildContext context, int index) => const Divider(),
              itemCount: widget.values.length,
              itemBuilder: (BuildContext context, int index) => _buildTransactionRow(widget.values[index]),
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
                MoneyWidget(
                  amountModel: MoneyModel(
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

  String buildTallyOfItemsToImportOrSkip() {
    final int totalItems = widget.values.length;
    final int itemsToImport = widget.values.where((ValuesQuality item) => !item.exist).length;
    String text = getIntAsText(widget.values.length);
    if (totalItems != itemsToImport) {
      text = '${getIntAsText(itemsToImport)}/${getIntAsText(totalItems)}';
    }
    return '$text entries';
  }

  double sumOfValues() {
    double sum = 0;
    for (final ValuesQuality value in widget.values) {
      sum += value.amount.asAmount();
    }
    return sum;
  }

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
          Expanded(flex: 1, child: dateAsWidget),
          Expanded(flex: 2, child: payeeAsWidget),
          Expanded(flex: 1, child: amountAsWidget),
        ],
      ),
    );
  }

  void _sortValues() {
    ValuesQuality.sort(widget.values, _sortColumnIndex, _sortAscending);
  }

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
