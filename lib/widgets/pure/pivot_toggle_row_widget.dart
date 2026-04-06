import 'package:flutter/material.dart';

/// Builds a horizontally scrollable row of [ToggleButtons] used by pivot filters.
Widget buildPivotToggleRow({
  Key? key,
  required List<bool> isSelected,
  required List<Widget> children,
  required ValueChanged<int> onPressed,
  required EdgeInsetsGeometry padding,
  required BorderRadius borderRadius,
  required double minHeight,
  required double minWidth,
}) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: padding,
    child: ToggleButtons(
      key: key,
      direction: Axis.horizontal,
      onPressed: onPressed,
      borderRadius: borderRadius,
      constraints: BoxConstraints(minHeight: minHeight, minWidth: minWidth),
      isSelected: isSelected,
      children: children,
    ),
  );
}
