// Imports
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/sankey/sankey_colors_model.dart';
import 'package:money/widgets/sankey/sankey_entry_model.dart';
import 'package:money/widgets/sankey/sankey_helper.dart';

// Exports
export 'package:money/widgets/sankey/sankey_colors_model.dart';
export 'package:money/widgets/sankey/sankey_entry_model.dart';
export 'package:money/widgets/sankey/sankey_helper.dart';

const double _columnWidthDivisor = 5;
const double _topCenterGapMultiplier = 2;
const double _stackGapMultiplier = 5;
const double _channelNudge = 1;
const double _incomeBlockHeightCompact = 200;
const double _incomeBlockHeightRegular = 300;

/// A stateless widget for sankey widget.
class SankeyWidget extends StatelessWidget {
  /// Constructor
  const SankeyWidget({
    super.key,
    required this.leftEntries,
    required this.rightEntries,
    required this.colors,
    required this.compactView,
  });

  final SankeyColors colors;
  final bool compactView;
  final List<SanKeyEntry> leftEntries;
  final List<SanKeyEntry> rightEntries;

  @override
  Widget build(Object context) {
    return CustomPaint(
      painter: _SankeyPainter(
        leftEntries: leftEntries,
        rightEntries: rightEntries,
        compactView: compactView,
        colors: colors,
      ),
    );
  }
}

class _SankeyPainter extends CustomPainter {
  /// Constructor
  _SankeyPainter({
    required this.leftEntries,
    required this.rightEntries,
    required this.colors,
    required this.compactView,
  });

  final bool compactView;
  final List<SanKeyEntry> leftEntries;
  final List<SanKeyEntry> rightEntries;

  SankeyColors colors;
  double columnWidth = 0;
  double gap = Constants.gapBetweenChannels;
  double topOfCenters = Constants.gapBetweenChannels * _topCenterGapMultiplier;

  @override
  void paint(final Canvas canvas, final Size size) {
    columnWidth = size.width / _columnWidthDivisor;

    final double maxWidth = size.width;
    final double horizontalCenter = maxWidth / 2;

    double verticalStackOfTargets = topOfCenters;

    final double totalIncome = leftEntries.fold(
      0.00,
      (final double sum, final SanKeyEntry item) => sum + item.value,
    );
    final double totalExpense = rightEntries
        .fold(
          0.00,
          (final double sum, final SanKeyEntry item) => sum + item.value,
        )
        .abs();

    final double bestHeightForIncomeBlock = compactView ? _incomeBlockHeightCompact : _incomeBlockHeightRegular;

    final double ratioIncomeToExpense = bestHeightForIncomeBlock / (totalIncome + totalExpense);

    // Box for "Revenue"
    double lastHeight = ratioIncomeToExpense * totalIncome;
    lastHeight = max(Block.minBlockHeight, lastHeight);
    final Block targetRevenues = Block(
      '${AppL10n.tr(AppTranslationKeys.incomes)}${SharedStrings.lineFeed}${getAmountAsShorthandText(totalIncome)}',
      ui.Rect.fromLTWH(
        horizontalCenter - columnWidth,
        verticalStackOfTargets,
        columnWidth,
        lastHeight,
      ),
      colors.colorIncome,
      colors.textColor,
      TextAlign.center,
      TextAlign.center,
    );

    // Box for "Total Expenses"
    verticalStackOfTargets += gap + lastHeight;
    lastHeight = ratioIncomeToExpense * totalExpense;
    lastHeight = max(Block.minBlockHeight, lastHeight);
    final Block targetExpenses = Block(
      '${AppL10n.tr(AppTranslationKeys.expenses)}${SharedStrings.lineFeed}-${getAmountAsShorthandText(totalExpense)}',
      ui.Rect.fromLTWH(
        horizontalCenter + gap,
        topOfCenters,
        columnWidth,
        lastHeight,
      ),
      colors.colorExpense,
      colors.textColor,
      TextAlign.center,
      TextAlign.center,
    );

    // Left Side - "Source of Incomes"
    double stackVerticalPosition = 0.0;

    stackVerticalPosition += renderSourcesToTarget(
      canvas,
      leftEntries,
      0,
      stackVerticalPosition,
      targetRevenues,
      colors.colorIncome,
      colors.textColor,
    );

    stackVerticalPosition += gap * _stackGapMultiplier;

    // Right Side - "Source of Expenses"
    stackVerticalPosition += renderSourcesToTarget(
      canvas,
      rightEntries,
      maxWidth - columnWidth,
      0,
      targetExpenses,
      colors.colorExpense,
      colors.textColor,
    );

    final double heightProfitFromIncomeSection = targetRevenues.rect.height - targetExpenses.rect.height;

    // Render Channel from "Revenue" to "Expenses"
    drawChanel(
      canvas: canvas,
      // right side of the Revenues Box
      start: ChannelPoint(
        targetRevenues.rect.right,
        targetRevenues.rect.top,
        targetRevenues.rect.bottom - heightProfitFromIncomeSection,
      ),
      // Left side of the Expenses box
      end: ChannelPoint(
        targetExpenses.rect.left + _channelNudge,
        targetExpenses.rect.top,
        targetExpenses.rect.bottom,
      ),
      color: colors.colorExpense,
    );

    // Render from "Revenues" remaining profit to "Net" box
    // Box for "Net Profit/Lost"
    final double netAmount = totalIncome - totalExpense;
    renderNetProfitOrLost(
      netAmount,
      lastHeight,
      ratioIncomeToExpense,
      horizontalCenter,
      targetRevenues,
      targetExpenses,
      canvas,
      heightProfitFromIncomeSection,
    );
  }

  @override
  bool shouldRebuildSemantics(final _SankeyPainter oldDelegate) => false;

  @override
  bool shouldRepaint(final _SankeyPainter oldDelegate) => true;

  // Box for "Net Profit/Lost"
  // The box may show on both side
  // The right when depicting a "Net Profit"
  // or
  // The left when depicting a "Net Lost"
  /// Builds the net profit/loss block positioned left or right of center.
  Block buildSegmentForNetProfitLost(
    double netAmount,
    double lastHeight,
    double ratioIncomeToExpense,
    double horizontalCenter,
    Block targetRevenues,
    Block targetExpenses,
  ) {
    lastHeight = ratioIncomeToExpense * netAmount.abs();
    lastHeight = max(Block.minBlockHeight, lastHeight);

    String text = SharedStrings.empty;

    late Rect rect;
    late double netRectLeft;
    late double netRectTop;

    if (netAmount < 0) {
      // Net Lost
      text += AppL10n.tr(AppTranslationKeys.loss) + SharedStrings.lineFeed;
      netRectLeft = horizontalCenter - (columnWidth + gap);
      netRectTop = targetRevenues.rect.bottom + gap;
    } else {
      // Net Profit
      text += AppL10n.tr(AppTranslationKeys.profit) + SharedStrings.lineFeed;
      netRectLeft = horizontalCenter + gap;
      netRectTop = targetExpenses.rect.bottom + gap;
    }

    rect = ui.Rect.fromLTWH(netRectLeft, netRectTop, columnWidth, lastHeight);

    text += getAmountAsShorthandText(netAmount);

    final Block targetNet = Block(
      text,
      rect,
      colors.colorNet,
      colors.textColor,
      TextAlign.center,
      TextAlign.center,
    );

    return targetNet;
  }

  // Box for "Net Profit/Lost"
  // The box may show on both side
  // The right when depicting a "Net Profit"
  // or
  // The left when depicting a "Net Lost"
  /// Renders the net profit/loss block and its connecting channels.
  void renderNetProfitOrLost(
    double netAmount,
    double lastHeight,
    double ratioIncomeToExpense,
    double horizontalCenter,
    Block targetRevenues,
    Block targetExpenses,
    ui.Canvas canvas,
    double heightProfitFromIncomeSection,
  ) {
    final Block targetNet = buildSegmentForNetProfitLost(
      netAmount,
      lastHeight,
      ratioIncomeToExpense,
      horizontalCenter,
      targetRevenues,
      targetExpenses,
    );
    targetNet.draw(canvas);

    late ChannelPoint netStart;
    late ChannelPoint netEnd;
    if (netAmount < 0) {
      netStart = ChannelPoint(
        targetNet.rect.right - 1,
        targetNet.rect.top,
        targetNet.rect.bottom,
      );
      netEnd = ChannelPoint(
        targetRevenues.rect.right,
        targetRevenues.rect.bottom,
        targetExpenses.rect.bottom,
      );
    } else {
      netStart = ChannelPoint(
        targetRevenues.rect.right,
        targetRevenues.rect.bottom - heightProfitFromIncomeSection,
        targetRevenues.rect.bottom,
      );
      netEnd = ChannelPoint(
        targetNet.rect.left + _channelNudge,
        targetNet.rect.top,
        targetNet.rect.bottom,
      );
    }

    drawChanel(
      canvas: canvas,
      start: netStart,
      end: netEnd,
      color: colors.colorNet,
    );
  }

  /// Renders a list of source blocks and channels to a target block.
  double renderSourcesToTarget(
    final ui.Canvas canvas,
    final List<SanKeyEntry> list,
    final double left,
    final double top,
    final Block target,
    final Color color,
    final Color textColor,
  ) {
    final double sumOfHeight = sumValue(list);

    final double ratioPriceToHeight = target.rect.height / sumOfHeight.abs();

    double verticalPosition = 0.0;

    final List<Block> blocks = <Block>[];

    // Prepare the sources (Left Side)
    for (SanKeyEntry element in list) {
      // Prepare a Left Block
      final double height = max(
        Constants.minBlockHeight,
        element.value.abs() * ratioPriceToHeight,
      );
      final double boxTop = top + verticalPosition;
      final ui.Rect rect = Rect.fromLTWH(left, boxTop, columnWidth, height);
      final String text = compactView ? shortenLongText(element.name) : element.name;
      final Block source = Block(
        '$text: ${getAmountAsShorthandText(element.value)}',
        rect,
        color,
        textColor,
        TextAlign.center,
        TextAlign.center,
      );
      source.textColor = textColor;
      blocks.add(source);

      verticalPosition += height + gap;
    }

    renderSourcesToTargetAsPercentage(canvas, blocks, target);

    // Draw the target box and text last to ensure that its on top
    target.draw(canvas);

    // how much vertical space was needed to render this
    return verticalPosition;
  }
}
