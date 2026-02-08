import 'package:money/data/entities/category.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/category_types.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const int _zeroInt = 0;
const int _percentageScale = 100;
const double _zeroDouble = 0.0;
const double _fullOpacity = 1.0;
const double _emptyOpacity = 0.0;
const double _barRadius = 3.0;
const double _barHeight = 20.0;
const double _segmentGap = 1.0;
const double _segmentFontSize = 9.0;
const int _detailFlex = 2;

class Distribution {
  Distribution({required this.category, required this.amount});

  final double amount;
  final Category category;

  double percentage = 0;
}

class DistributionBar extends StatefulWidget {
  const DistributionBar({required this.segments, super.key});

  final List<Distribution> segments;

  @override
  State<DistributionBar> createState() => _DistributionBarState();
}

class _DistributionBarState extends State<DistributionBar> {
  final List<Widget> detailRowWidgets = <Widget>[];
  final List<Widget> segmentWidgets = <Widget>[];

  @override
  Widget build(BuildContext context) {
    detailRowWidgets.clear();
    segmentWidgets.clear();

    final double sum = widget.segments.fold(
      _zeroDouble,
      (double previousValue, Distribution element) => previousValue + element.amount.abs(),
    );
    if (sum > _zeroDouble) {
      for (final Distribution segment in widget.segments) {
        segment.percentage = segment.amount.abs() / sum;
      }
    }
    // Sort descending by percentage
    widget.segments.sort(
      (Distribution a, Distribution b) => b.percentage.compareTo(a.percentage),
    );

    _buildWidgets(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _buildHorizontalBar(),
        gapSmall(),
        _buildRowOfDetails(),
      ],
    );
  }

  Widget _buildDetailRow(
    final BuildContext context,
    final Category category,
    final double value,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        gapSmall(),
        Expanded(flex: _detailFlex, child: category.getColorAndNameWidget()),
        Expanded(
          child: WidgetFromData(amountModel: AmountModel(amount: value)),
        ),
        Opacity(
          opacity: category.isExpense ? _fullOpacity : _emptyOpacity,
          child: Checkbox(
            value: category.isRecurring,
            onChanged: (bool? value) {
              if (category.isExpense) {
                setState(() {
                  category.mutateField(
                    'Type',
                    value == true ? CategoryType.recurringExpense.index : CategoryType.expense.index,
                    true,
                  );
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_barRadius), // Radius for rounded ends
      child: SizedBox(
        height: _barHeight,
        child: Row(children: segmentWidgets),
      ),
    );
  }

  Widget _buildRowOfDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: detailRowWidgets,
    );
  }

  void _buildWidgets(final BuildContext context) {
    for (final Distribution segment in widget.segments) {
      Color backgroundColorOfSegment = segment.category.getColorOrAncestorsColor();
      Color foregroundColorOfSegment = contrastColor(backgroundColorOfSegment);

      if (backgroundColorOfSegment.a == 0) {
        backgroundColorOfSegment = Colors.grey;
        foregroundColorOfSegment = Colors.white;
      }

      segmentWidgets.add(
        Expanded(
          // use the percentage to determine the relative width
          flex: (segment.percentage * _percentageScale).toInt().abs(),
          child: Tooltip(
            message: segment.category.fieldName.value,
            child: Container(
              alignment: Alignment.center,
              color: backgroundColorOfSegment,
              margin: EdgeInsets.only(
                right: segment == widget.segments.last ? _zeroDouble : _segmentGap,
              ),
              child: _builtSegmentOverlayText(
                segment.percentage,
                foregroundColorOfSegment,
              ),
            ),
          ),
        ),
      );

      detailRowWidgets.add(
        _buildDetailRow(context, segment.category, segment.amount),
      );
    }
  }

  Widget _builtSegmentOverlayText(final double percentage, final Color color) {
    final int value = (percentage * _percentageScale).toInt();
    if (value <= _zeroInt) {
      return const SizedBox();
    }
    return Text(
      '$value%',
      softWrap: false,
      overflow: TextOverflow.clip,
      style: TextStyle(color: color, fontSize: _segmentFontSize),
    );
  }
}
