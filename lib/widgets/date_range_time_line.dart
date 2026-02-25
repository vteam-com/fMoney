import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';

const int _inclusiveYearCount = 1;
const double _tickWidth = 1;
const double _tickHeight = 5;
const double _tickAlpha = 0.5;

/// A stateless widget for date range timeline.
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
    final int numYears = (endDate.year - startDate.year) + _inclusiveYearCount;
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
            Text(
              AppL10n.tr(AppTranslationKeys.countYears, params: <String, String>{'count': numYears.toString()}),
              style: style,
            ),

            // End year
            Text('${endDate.year}', style: style),
          ],
        ),
      ],
    );
  }
}

/// Builds a list of tick widgets for the timeline ruler.
List<Widget> ticks(final int numberOfTicks) {
  final List<Widget> widgets = <Widget>[];

  for (int tick = 0; tick < numberOfTicks; tick++) {
    widgets.add(
      Container(
        width: _tickWidth,
        height: _tickHeight,
        decoration: BoxDecoration(
          // shape: BoxShape.circle,
          color: Colors.grey.withValues(alpha: _tickAlpha),
        ),
      ),
    );
  }
  return widgets;
}
