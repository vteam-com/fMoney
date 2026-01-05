import 'package:flutter/material.dart';
import 'package:money/helpers/constants.dart';

/// If the space for rendering the widget is too small this will scale the widget to fit
Widget scaleDown(
  final Widget child, [
  final AlignmentGeometry alignment = Alignment.center,
]) {
  return FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child);
}

extension ViewExtension on BuildContext {
  bool get isWidthSmall => MediaQuery.of(this).size.width <= Constants.screenWidthSmall;
  bool get isWidthMedium => MediaQuery.of(this).size.width <= Constants.screenWidthMedium;
  bool get isWidthLarge => MediaQuery.of(this).size.width > Constants.screenWidthMedium;
}
