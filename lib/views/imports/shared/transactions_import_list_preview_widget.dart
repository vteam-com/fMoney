import 'package:money/data/models/ranges_model.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/pairs_model.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/widgets/columns/column_header_button.dart';
import 'package:money/widgets/columns/value_parser.dart';
import 'package:money/widgets/columns/value_quality.dart';
import 'package:money/widgets/components/my_banner_widget.dart';
import 'package:money/widgets/components/semantic_text_widget.dart';
import 'package:money/widgets/pure/box_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:money/widgets/pure/quantity_widget.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const int _columnFlexDate = 1;
const int _columnFlexDescription = 2;
const int _columnFlexAmount = 1;
const int _columnFlexQuantity = 1;
const int _columnFlexPrice = 1;
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
    // Use double.infinity so Box fills the dialog's available width.
    // LayoutBuilder cannot be used here because AlertDialog queries intrinsic
    // dimensions, which LayoutBuilder does not support.
    const double boxWidth = double.infinity;

    if (widget.values.isEmpty) {
      return Box(
        title: AppL10n.tr(AppTranslationKeys.preview),
        width: boxWidth,
        padding: SizeForPadding.huge,
        child: buildWarning(context, AppL10n.tr(AppTranslationKeys.noTransactions)),
      );
    }

    _sortValues();

    return Box(
      width: boxWidth,
      header: buildHeaderTitleAndCounter(
        context,
        AppL10n.tr(AppTranslationKeys.preview),
        buildTallyOfItemsToImportOrSkip(),
      ),
      copyToClipboard: () {
        final String text = widget.values.toList().join(SharedStrings.lineFeed);
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
                Text(
                  AppL10n.tr(AppTranslationKeys.total),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: SizeForText.small),
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
    return AppL10n.tr(
      AppTranslationKeys.entriesCount,
      params: <String, String>{'count': text},
    );
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
          Badge(
            label: Text(AppL10n.tr(AppTranslationKeys.payeeMatch)),
            backgroundColor: Colors.lightBlue,
            textColor: Colors.black,
          ),
      ],
    );
  }

  /// Wraps a cell widget and aligns it to the right edge.
  Widget _buildRightAlignedCell(Widget child) {
    return Align(
      alignment: Alignment.centerRight,
      child: child,
    );
  }

  /// Builds a single preview row for an imported transaction.
  Widget _buildTransactionRow(ValuesQuality value) {
    final Widget dateAsWidget = value.date.valueAsDateWidget(context);
    final Widget payeeAsWidget = _buildDescriptionOrPayee(
      context,
      value.description,
    );

    final List<Widget> rowChildren = <Widget>[
      Expanded(flex: _columnFlexDate, child: dateAsWidget),
      Expanded(flex: _columnFlexDescription, child: payeeAsWidget),
    ];

    // Add quantity and price columns if stock info is present
    if (_hasStockInfo) {
      final Widget quantityAsWidget = value.stockQuantity != 0
          ? QuantityWidget(quantity: value.stockQuantity)
          : const SizedBox.shrink();
      rowChildren.add(
        Expanded(flex: _columnFlexQuantity, child: _buildRightAlignedCell(quantityAsWidget)),
      );

      final Widget priceAsWidget = value.stockPrice > 0
          ? WidgetFromData.fromDouble(value.stockPrice)
          : const SizedBox.shrink();
      rowChildren.add(
        Expanded(flex: _columnFlexPrice, child: _buildRightAlignedCell(priceAsWidget)),
      );
    }

    final Widget amountAsWidget = value.amount.valueAsAmountWidget(context);
    rowChildren.add(
      Expanded(flex: _columnFlexAmount, child: _buildRightAlignedCell(amountAsWidget)),
    );

    return MyBanner(
      on: value.exist,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: rowChildren,
      ),
    );
  }

  /// Builds the dynamic column names list based on whether stock info exists.
  List<Triple<String, TextAlign, int>> get _columnNames {
    final List<Triple<String, TextAlign, int>> columns = <Triple<String, TextAlign, int>>[
      Triple<String, TextAlign, int>(
        AppL10n.tr(AppTranslationKeys.date),
        TextAlign.left,
        _columnFlexDate,
      ),
      Triple<String, TextAlign, int>(
        AppL10n.tr(AppTranslationKeys.descriptionPayee),
        TextAlign.left,
        _columnFlexDescription,
      ),
    ];

    // Add quantity and price columns if any value has stock info
    if (_hasStockInfo) {
      columns.add(
        Triple<String, TextAlign, int>(
          AppL10n.tr(AppTranslationKeys.quantity),
          TextAlign.right,
          _columnFlexQuantity,
        ),
      );
      columns.add(
        Triple<String, TextAlign, int>(
          AppL10n.tr(AppTranslationKeys.price),
          TextAlign.right,
          _columnFlexPrice,
        ),
      );
    }

    columns.add(
      Triple<String, TextAlign, int>(
        AppL10n.tr(AppTranslationKeys.amount),
        TextAlign.right,
        _columnFlexAmount,
      ),
    );

    return columns;
  }

  /// Detects if any values have stock information.
  bool get _hasStockInfo {
    return widget.values.any((ValuesQuality v) => v.hasStockInfo());
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
