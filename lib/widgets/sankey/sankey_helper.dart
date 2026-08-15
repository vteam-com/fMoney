// ignore: fcheck_one_class_per_file

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:money/widgets/sankey/sankey_entry_model.dart';

const double _defaultFontSize = 12;
const double _defaultRotation = 0;
const double _centerFraction = 0.5;
const double _channelHeight = 100;
const double _defaultBlockX = 0.0;
const double _defaultBlockY = 0.0;
const double _defaultBlockWidth = 10.0;
const double _defaultBlockHeight = 20.0;
const Color _defaultChannelColor = Color(0xFF56687A);

/// Represents channel point.
class ChannelPoint {
  ChannelPoint(this.x, this.top, this.bottom) {
    //
  }

  double bottom = 0 / 0;
  double top = 0.0;
  double x = 0.0;
}

/// Represents block.
class Block {
  /// Constructor
  Block(
    this.name,
    this.rect,
    this.color,
    this.textColor,
    this.alignHorizontal,
    this.alignVertical,
  );

  TextAlign alignHorizontal = TextAlign.start;
  TextAlign alignVertical = TextAlign.start;
  Color color;
  String name = '';
  Rect rect = const Rect.fromLTWH(_defaultBlockX, _defaultBlockY, _defaultBlockWidth, _defaultBlockHeight);
  Color textColor = Colors.black;

  static const double blockWidth = 50.0;
  static const double minBlockHeight = 20.0;

  /// Draws the block rectangle and centered text onto the canvas.
  void draw(Canvas canvas) {
    if (!rect.hasNaN) {
      // Rectangle
      final ui.Paint paint = Paint();
      paint.color = color;
      paint.style = PaintingStyle.fill;
      canvas.drawRect(rect, paint);

      // Title
      drawTextInRect(
        canvas,
        name,
        rect,
        color: textColor,
        textAlign: alignHorizontal,
      );
    }
  }
}

/// Renders source blocks and percentage-based channels to a target block.
void renderSourcesToTargetAsPercentage(
  ui.Canvas canvas,
  List<Block> list,
  Block target,
) {
  final double sumOfHeight = sumHeight(list);

  double rollingVerticalPositionDrawnOnTheTarget = target.rect.top;

  for (Block block in list) {
    final double ratioSourceBlockHeightToSumHeight = block.rect.height / sumOfHeight;
    final double targetSectionHeight = target.rect.height * ratioSourceBlockHeightToSumHeight;

    final double blockSideToStartFrom = target.rect.center.dx > block.rect.center.dx
        ? block.rect.right - 1
        : block.rect.left + 1;
    final double targetSideToStartFrom = target.rect.center.dx > block.rect.center.dx
        ? target.rect.left + 1
        : target.rect.right - 1;

    drawChanel(
      canvas: canvas,
      start: ChannelPoint(
        blockSideToStartFrom,
        block.rect.top,
        block.rect.bottom,
      ),
      end: ChannelPoint(
        targetSideToStartFrom,
        rollingVerticalPositionDrawnOnTheTarget,
        rollingVerticalPositionDrawnOnTheTarget + targetSectionHeight,
      ),
      color: block.color,
    );

    rollingVerticalPositionDrawnOnTheTarget += targetSectionHeight;
    block.draw(canvas);
  }
}

/// Draws centered text inside a rectangle with optional rotation.
void drawTextInRect(
  Canvas context,
  String name,
  Rect rect, {
  TextAlign textAlign = TextAlign.left,
  Color color = Colors.black,
  double fontSize = _defaultFontSize,
  double angleRotationInRadians = _defaultRotation,
}) {
  context.save();
  context.translate(rect.left, rect.top);
  context.rotate(angleRotationInRadians);
  final TextSpan span = TextSpan(
    style: TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
    ),
    text: name,
  );

  final TextPainter textPainter = TextPainter(
    text: span,
    textAlign: textAlign,
    textDirection: ui.TextDirection.ltr,
  );

  textPainter.layout();

  textPainter.paint(
    context,
    Offset(
      // Do calculations here:
      (rect.width - textPainter.width) * _centerFraction,
      (rect.height - textPainter.height) * _centerFraction,
    ),
  );
  context.restore();
}

/// Draws a curved channel between two vertical points.
void drawChanel({
  required ui.Canvas canvas,
  required ChannelPoint start,
  required ChannelPoint end,
  Color color = _defaultChannelColor,
}) {
  // We render left to right, so lets see what channel goes on the left and the one that goes on the right
  final ChannelPoint channelPointLeft = (start.x < end.x) ? start : end;
  final ChannelPoint channelPointEnd = (start.x < end.x) ? end : start;

  final ui.Size size = Size(
    (channelPointEnd.x - channelPointLeft.x).abs(),
    _channelHeight,
  );
  final double halfWidth = size.width / 2;

  final ui.Path path = Path();

  // Start from the Left-Top
  path.moveTo(channelPointLeft.x, channelPointLeft.top);
  path.cubicTo(
    /*P1*/
    channelPointLeft.x + halfWidth,
    channelPointLeft.top,
    /*P2*/
    channelPointEnd.x - halfWidth,
    channelPointEnd.top,
    /*P3*/
    channelPointEnd.x,
    channelPointEnd.top,
  );

  path.lineTo(channelPointEnd.x, channelPointEnd.bottom);

  path.cubicTo(
    /*P1*/
    channelPointEnd.x - halfWidth,
    channelPointEnd.bottom,
    /*P2*/
    channelPointLeft.x + halfWidth,
    channelPointLeft.bottom,
    /*P3*/
    channelPointLeft.x,
    channelPointLeft.bottom,
  );

  // Close at the Left-Bottom
  path.close();

  final ui.Paint paint = Paint();
  paint.color = color;
  paint.style = PaintingStyle.fill;
  canvas.drawPath(path, paint);

  // OUTLINE
  // final ui.Paint paintStroke = Paint();
  // paintStroke.style = PaintingStyle.stroke;
  // paintStroke.strokeWidth = 0;
  // paintStroke.color = color;
  // canvas.drawPath(path, paintStroke);
}

/// Sums the heights of a list of blocks.
double sumHeight(List<Block> list) {
  final double sumOfHeight = list.fold(
    0.0,
    (double previousValue, Block element) => previousValue + element.rect.height,
  );
  return sumOfHeight;
}

/// Sums the values of a list of SanKeyEntry items.
double sumValue(List<SanKeyEntry> list) {
  final double sumOfHeight = list.fold(
    0.0,
    (double previousValue, SanKeyEntry element) => previousValue + element.value,
  );
  return sumOfHeight;
}
