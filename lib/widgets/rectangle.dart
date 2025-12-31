import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class MyRectangle extends StatelessWidget {
  const MyRectangle({
    required this.size,
    required this.colorFill,
    super.key,
    this.colorBorder = Colors.grey,
    this.shape = BoxShape.rectangle,
    this.showBorder = false,
    this.borderSize = 2,
  });

  final double borderSize;
  final Color colorBorder;
  final Color colorFill;
  final BoxShape shape;
  final bool showBorder;
  final double size;

  @override
  Widget build(final BuildContext context) {
    return DottedBorder(
      options: CircularDottedBorderOptions(
        padding: EdgeInsets.zero,
        dashPattern: colorFill == Colors.transparent ? const <double>[4.0, 2.0] : const <double>[100.0, 0.0],
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
