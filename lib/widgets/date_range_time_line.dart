import 'package:money/helpers/color_helper.dart';

class DateRangeTimeline extends StatelessWidget {
  const DateRangeTimeline({
    required this.startDate,
    required this.endDate,
    super.key,
    this.showTicks = true,
  });

  final DateTime endDate;
  final bool showTicks;
  final DateTime startDate;

  @override
  Widget build(BuildContext context) {
    // Calculate the number of years between the start and end dates
    final int numYears = (endDate.year - startDate.year) + 1;
    final TextStyle style = getTextTheme(context).labelSmall!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (showTicks)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ticks(numYears),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // Start year
            Text('${startDate.year}', style: style),

            // Number of years
            Text('$numYears years', style: style),

            // End year
            Text('${endDate.year}', style: style),
          ],
        ),
      ],
    );
  }
}

List<Widget> ticks(final int numberOfTicks) {
  final List<Widget> widgets = <Widget>[];

  for (int tick = 0; tick < numberOfTicks; tick++) {
    widgets.add(
      Container(
        width: 1,
        height: 5,
        decoration: BoxDecoration(
          // shape: BoxShape.circle,
          color: Colors.grey.withValues(alpha: 0.5),
        ),
      ),
    );
  }
  return widgets;
}
