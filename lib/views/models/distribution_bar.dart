import 'package:money/helpers/category_types.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/views/models/categories/category.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/money_model.dart';
import 'package:money/widgets/money_widget.dart';

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
      0,
      (double previousValue, Distribution element) => previousValue + element.amount.abs(),
    );
    if (sum > 0) {
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
        Expanded(flex: 2, child: category.getColorAndNameWidget()),
        Expanded(
          child: MoneyWidget(amountModel: MoneyModel(amount: value)),
        ),
        Opacity(
          opacity: category.isExpense ? 1 : 0,
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
      borderRadius: BorderRadius.circular(3), // Radius for rounded ends
      child: SizedBox(height: 20, child: Row(children: segmentWidgets)),
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
          flex: (segment.percentage * 100).toInt().abs(),
          child: Tooltip(
            message: segment.category.fieldName.value,
            child: Container(
              alignment: Alignment.center,
              color: backgroundColorOfSegment,
              margin: EdgeInsets.only(
                right: segment == widget.segments.last ? 0.0 : 1.0,
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
    final int value = (percentage * 100).toInt();
    if (value <= 0) {
      return const SizedBox();
    }
    return Text(
      '$value%',
      softWrap: false,
      overflow: TextOverflow.clip,
      style: TextStyle(color: color, fontSize: 9),
    );
  }
}
