import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/pairs.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/views/data.dart';
import 'package:money/views/distribution_bar.dart';
import 'package:money/views/transactions.dart';
import 'package:money/views/view_cashflow/recurring/recurring_payment.dart';
import 'package:money/widgets/date_range_time_line.dart';
import 'package:money/widgets/mini_timeline_daily.dart';
import 'package:money/widgets/mini_timeline_twelve_months.dart';
import 'package:money/widgets/preferences_controller.dart';
import 'package:money/widgets/pure/box.dart';
import 'package:money/widgets/pure/gaps.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const double _cardMarginBottom = 21.0;
const double _cardElevation = 4.0;
const double _cardWidth = 400.0;
const double _cardPadding = 13.0;
const double _cardSpacing = 21.0;
const double _averagesChartHeight = 55.0;
const double _timelineHeight = 50.0;
const double _dividerHeight = 1.0;
const double _dateRangePadding = 100.0;
const double _indexOpacity = 0.5;

/// A stateless widget for recurring card.
class RecurringCard extends StatelessWidget {
  const RecurringCard({
    required this.index,
    required this.dateRangeSearch,
    required this.dateRangeSelected,
    required this.payment,
    required this.forIncomeTransaction,
    super.key,
  });

  final DateRange dateRangeSearch;
  final DateRange dateRangeSelected;
  final bool forIncomeTransaction;
  final int index;
  final RecurringPayment payment;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: getColorTheme(context).surface,
      margin: const EdgeInsets.only(bottom: _cardMarginBottom),
      elevation: _cardElevation,
      child: Container(
        width: _cardWidth,
        padding: const EdgeInsets.all(_cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Header
            _buildHeader(context),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: _cardSpacing,
              runSpacing: _cardSpacing,
              children: <Widget>[
                // Time line
                _buildBoxTimelinePerDayOverYears(context),

                // break down the numbers
                _buildBoxAverages(context),

                // Category Distributions
                _buildBoxDistribution(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the averages box showing yearly, monthly, and daily averages.
  Widget _buildBoxAverages(final BuildContext context) {
    return Box(
      title: 'Averages',
      padding: _cardSpacing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            height: _averagesChartHeight,
            margin: const EdgeInsets.symmetric(vertical: SizeForPadding.medium),
            child: MiniTimelineTwelveMonths(
              values: payment.averagePerMonths,
              color: getColorTheme(context).primary,
            ),
          ),

          // Average per yearS
          _buildTextAmountRow(
            context,
            'Year',
            payment.total / (payment.dateRangeFound.durationInYears),
          ),
          // Average per month
          _buildTextAmountRow(
            context,
            'Month',
            payment.total / (payment.dateRangeFound.durationInMonths),
          ),
          // Average per day
          _buildTextAmountRow(
            context,
            'Day',
            payment.total / (payment.dateRangeFound.durationInDays),
          ),
        ],
      ),
    );
  }

  /// Builds the category distribution box for the payment's category breakdown.
  Widget _buildBoxDistribution(final BuildContext _) {
    return Box(
      title: 'Categories',
      padding: _cardSpacing,
      child: DistributionBar(segments: payment.categoryDistribution),
    );
  }

  /// Builds the timeline box showing daily sums over the searched date range.
  Widget _buildBoxTimelinePerDayOverYears(final BuildContext context) {
    final List<Pair<int, double>> sumByDays = Transactions.transactionSumByTime(
      payment.transactions,
    );

    return Box(
      title: 'Timeline',
      padding: _cardSpacing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            height: _timelineHeight,
            child: MiniTimelineDaily(
              values: sumByDays,
              yearStart: dateRangeSearch.min!.year,
              yearEnd: dateRangeSearch.max!.year,
              offsetStartingDay: dateRangeSearch.min!.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay,
              color: getColorTheme(context).primary,
            ),
          ),
          const Divider(height: _dividerHeight, thickness: _dividerHeight),
          _buildDateRangeRow(payment.dateRangeFound, _dateRangePadding, _dateRangePadding, false),
          gapLarge(),
          _buildTextAmountRow(
            context,
            '${getIntAsText(payment.frequency)} transactions averaging',
            payment.total / payment.frequency,
          ),
        ],
      ),
    );
  }

  /// Builds a date range timeline row for the given [dateRange].
  Widget _buildDateRangeRow(
    final DateRange dateRange,
    final double paddingLeft,
    final double paddingRight,
    final bool showTicks,
  ) {
    return Padding(
      padding: EdgeInsets.only(left: paddingLeft, right: paddingRight),
      child: DateRangeTimeline(
        startDate: dateRange.min!,
        endDate: dateRange.max!,
        showTicks: showTicks,
      ),
    );
  }

  /// Builds the card header with payee name and total amount.
  Widget _buildHeader(final BuildContext context) {
    final TextTheme textTheme = getTextTheme(context);
    final String payeeName = Data().payees.getNameFromId(payment.payeeId);
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Opacity(opacity: _indexOpacity, child: Text('#$index ')),
        Expanded(
          child: Row(
            children: <Widget>[
              SelectableText(
                payeeName,
                maxLines: 1,
                style: textTheme.titleMedium,
              ),
              IconButton(
                onPressed: () {
                  switchViewTransactionForPayee(payeeName);
                },
                icon: const Icon(Icons.open_in_new),
              ),
            ],
          ),
        ),
        gapLarge(),
        WidgetFromData(amountModel: AmountModel(amount: payment.total)),
      ],
    );
  }
}

/// Builds a label/value row for an amount.
Widget _buildTextAmountRow(
  final BuildContext context,
  final String title,
  final double amount,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: <Widget>[
      Text(title, style: getTextTheme(context).labelMedium),
      WidgetFromData(amountModel: AmountModel(amount: amount)),
    ],
  );
}
