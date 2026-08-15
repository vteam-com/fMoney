import 'package:flutter/material.dart';

const double _diffBackgroundAlpha = 0.3;
const double _diffPadding = 2;
const double _diffFontSize = 10;

/// Wraps text in a red background to indicate an old value.
Widget diffTextOldValue(String text) {
  return diffText(
    text,
    Colors.red.withValues(alpha: _diffBackgroundAlpha), // Transparent red background color
    Colors.red, // Color for old value
    true,
  );
}

/// Wraps text in a green background to indicate a new value.
Widget diffTextNewValue(String text) {
  return diffText(
    text,
    Colors.green.withValues(alpha: _diffBackgroundAlpha), // Transparent red background color
    Colors.green, // Color for old value
    false,
  );
}

/// Wraps text in a colored background for diff display.
Widget diffText(
  String text,
  Color backgroundColor,
  Color _, // textColor,
  bool _, // lineTrough,
) {
  return Container(
    padding: const EdgeInsets.all(_diffPadding),
    color: backgroundColor,
    child: Text(text, style: const TextStyle(fontSize: _diffFontSize)),
  );
}
