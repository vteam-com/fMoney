import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

const double _defaultBorderSize = 2;
const List<double> _transparentDashPattern = <double>[4.0, 2.0];
const List<double> _solidDashPattern = <double>[100.0, 0.0];

/// A stateless widget for my rectangle.
class MyRectangle extends StatelessWidget {
  const MyRectangle({
    required this.size,
    required this.colorFill,
    super.key,
    this.colorBorder = Colors.grey,
    this.shape = BoxShape.rectangle,
    this.showBorder = false,
    this.borderSize = _defaultBorderSize,
  });

  final double borderSize;
  final Color colorBorder;
  final Color colorFill;
  final BoxShape shape;
  final bool showBorder;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      options: CircularDottedBorderOptions(
        padding: EdgeInsets.zero,
        dashPattern: colorFill == Colors.transparent ? _transparentDashPattern : _solidDashPattern,
        color: colorBorder,
        strokeWidth: borderSize,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: colorFill, shape: shape),
      ),
    );
  }
}
