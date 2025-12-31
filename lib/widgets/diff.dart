import 'package:flutter/material.dart';

Widget diffTextOldValue(final String text) {
  return diffText(
    text,
    Colors.red.withValues(alpha: 0.3), // Transparent red background color
    Colors.red, // Color for old value
    true,
  );
}

Widget diffTextNewValue(final String text) {
  return diffText(
    text,
    Colors.green.withValues(alpha: 0.3), // Transparent red background color
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
    padding: const EdgeInsets.all(2),
    color: backgroundColor,
    child: Text(text, style: const TextStyle(fontSize: 10)),
  );
}
