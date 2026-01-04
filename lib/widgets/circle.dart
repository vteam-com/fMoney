import 'package:flutter/material.dart';
import 'package:money/widgets/rectangle.dart';

class MyCircle extends StatelessWidget {
  const MyCircle({
    required this.colorFill,
    required this.size,
    super.key,
    this.colorBorder = Colors.grey,
    this.showBorder = false,
  });

  final Color colorBorder;
  final Color colorFill;
  final bool showBorder;
  final double size;

  @override
  Widget build(final BuildContext context) => MyRectangle(
    key: key,
    shape: BoxShape.circle,
    colorFill: colorFill,
    colorBorder: colorBorder,
    size: size,
    showBorder: showBorder,
  );
}
