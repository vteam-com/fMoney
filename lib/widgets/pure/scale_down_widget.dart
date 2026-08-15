import 'package:flutter/material.dart';
import 'package:money/helpers/constants_helper.dart';

/// If the space for rendering the widget is too small this will scale the widget to fit
Widget scaleDown(
  Widget child, [
  AlignmentGeometry alignment = Alignment.center,
]) {
  return FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child);
}

extension ViewExtension on BuildContext {
  /// True if the screen width is small or less.
  bool get isWidthSmall => MediaQuery.of(this).size.width <= Constants.screenWidthSmall;

  /// True if the screen width is medium or less.
  bool get isWidthMedium => MediaQuery.of(this).size.width <= Constants.screenWidthMedium;

  /// True if the screen width is large (greater than medium).
  bool get isWidthLarge => MediaQuery.of(this).size.width > Constants.screenWidthMedium;
}
