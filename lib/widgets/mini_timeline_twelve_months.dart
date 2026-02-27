import 'dart:math';

import 'package:flutter/material.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/pairs.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/vertical_line_with_tooltip.dart';

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
  Widget build(BuildContext _) {
    return LayoutBuilder(
      builder: (final BuildContext _, final BoxConstraints constraints) {
        final List<Widget> bars = <Widget>[];

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
              children: <Widget>[
                _buildMontLabel('J'),
                _buildMontLabel('F'),
                _buildMontLabel('M'),
                _buildMontLabel('A'),
                _buildMontLabel('M'),
                _buildMontLabel('J'),
                _buildMontLabel('J'),
                _buildMontLabel('A'),
                _buildMontLabel('S'),
                _buildMontLabel('O'),
                _buildMontLabel('N'),
                _buildMontLabel('D'),
              ],
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
