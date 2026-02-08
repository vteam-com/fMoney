import 'package:flutter/material.dart';

const double _diffBackgroundAlpha = 0.3;
const double _diffPadding = 2;
const double _diffFontSize = 10;

Widget diffTextOldValue(final String text) {
  return diffText(
    text,
    Colors.red.withValues(alpha: _diffBackgroundAlpha), // Transparent red background color
    Colors.red, // Color for old value
    true,
  );
}

Widget diffTextNewValue(final String text) {
  return diffText(
    text,
    Colors.green.withValues(alpha: _diffBackgroundAlpha), // Transparent red background color
    Colors.green, // Color for old value
    false,
  );
}

Widget diffText(
  final String text,
  final Color backgroundColor,
  final Color textColor,
  final bool lineTrough,
) {
  return Container(
    padding: const EdgeInsets.all(_diffPadding),
    color: backgroundColor,
    child: Text(text, style: const TextStyle(fontSize: _diffFontSize)),
  );
}
