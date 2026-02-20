import 'dart:math';

import 'package:flutter/material.dart';

const double _defaultLineWidth = 5;
const double _tooltipHeightFallback = 5;
const double _minLineHeight = 1;
const double _lineBorderRadius = 2;

/// A stateless widget for vertical line with tooltip.
class VerticalLineWithTooltip extends StatelessWidget {
  const VerticalLineWithTooltip({
    required this.height,
    required this.color,
    required this.tooltip,
    super.key,
    this.width = _defaultLineWidth,
  });

  final Color color;
  final double height;
  final String tooltip;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Tooltip(message: tooltip, child: _build());
  }

  Widget _build() {
    if (height == 0) {
      // we do this just to get the tooltip to work
      return SizedBox(height: _tooltipHeightFallback, width: width);
    } else {
      return Container(
        height: max(_minLineHeight, height),
        width: width,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(_lineBorderRadius),
        ),
      );
    }
  }
}
