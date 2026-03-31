import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/pairs.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/pure/vertical_line_with_tooltip.dart';

const int _monthsInYear = 12;

/// A stateless widget for mini timeline twelve months.
class MiniTimelineTwelveMonths extends StatelessWidget {
  const MiniTimelineTwelveMonths({
    required this.values,
    required this.color,
    super.key,
  });

  final Color color;
  final List<Pair<int, double>> values;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (final BuildContext _, final BoxConstraints constraints) {
        final List<Widget> bars = <Widget>[];
        final String locale = Localizations.localeOf(context).toLanguageTag();
        final DateFormat formatter = DateFormat.MMM(locale);
        final List<String> monthLabels = List<String>.generate(
          _monthsInYear,
          (int monthIndex) {
            final String shortMonth = formatter.format(DateTime(DateTime.now().year, monthIndex + 1, 1));
            if (shortMonth.isEmpty) {
              return '';
            }
            return shortMonth.substring(0, 1).toUpperCase();
          },
        );

        if (values.isNotEmpty) {
          num maxValue = 0;
          for (final Pair<int, double> p in values) {
            maxValue = max(maxValue, p.second.abs());
          }

          final double ratio = constraints.maxHeight / maxValue;
          for (final Pair<int, double> value in values) {
            final double height = value.second.abs() * ratio;
            bars.add(
              VerticalLineWithTooltip(
                height: height,
                color: color,
                tooltip: '${value.first} X ${doubleToCurrency(value.second)}',
              ),
            );
          }
        }

        return Column(
          children: <Widget>[
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: bars,
              ),
            ),
            const Divider(
              height: SizeForPadding.nano,
              thickness: SizeForPadding.nano,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: monthLabels.map(_buildMontLabel).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMontLabel(final String text) {
    return Text(text, style: const TextStyle(fontSize: SizeForText.nano));
  }
}
