import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:money/helpers/constants.dart';

/// If the space for rendering the widget is too small this will scale the widget to fit
Widget scaleDown(
  final Widget child, [
  final AlignmentGeometry alignment = Alignment.center,
]) {
  return FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child);
}

///
///                                       ------
/// Display a border and a question mark | ?    |
///                                       ------
///
Widget buildDashboardWidget(final Widget child) {
  return DottedBorder(
    options: RoundedRectDottedBorderOptions(
      color: Colors.grey.shade600,
      padding: const EdgeInsets.symmetric(horizontal: SizeForPadding.medium),
      radius: const Radius.circular(3),
    ),
    child: child,
  );
}

extension ViewExtension on BuildContext {
  bool get isWidthSmall => MediaQuery.of(this).size.width <= Constants.screenWidthSmall;
  bool get isWidthMedium => MediaQuery.of(this).size.width <= Constants.screenWidthMedium;
  bool get isWidthLarge => MediaQuery.of(this).size.width > Constants.screenWidthMedium;
}
