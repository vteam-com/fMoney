import 'package:flutter/material.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/views/panels/side_panel/side_panel_support.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/my_segment.dart';
import 'package:money/widgets/theme_controller.dart';
import 'package:money/widgets/widgets_domain/money_widget.dart';

class SidePanelHeader extends StatelessWidget {
  /// Constructor
  const SidePanelHeader({
    required this.isExpanded,
    required this.onExpanded, // SubView
    required this.subViewSelected,
    required this.subViewSelectionChanged, // Currency
    required this.currencyChoices,
    required this.currencySelected,
    required this.currentSelectionChanged,
    required this.sidePanelSupport,
    required this.actionButtons,
    super.key,
  });

  final List<Widget> Function(bool) actionButtons;

  final List<String> currencyChoices;

  final int currencySelected;

  final void Function(int) currentSelectionChanged;

  final bool isExpanded;

  final void Function(bool) onExpanded;

  final SidePanelSupport sidePanelSupport;

  final SidePanelSubViewEnum subViewSelected;

  final void Function(SidePanelSubViewEnum) subViewSelectionChanged;

  @override
  Widget build(final BuildContext context) {
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        return InkWell(
          onTap: () {
            onExpanded(!isExpanded);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _buildExpando(),
                _buildViewSelections(context, constraints),
                const Spacer(),
                IntrinsicWidth(child: Row(children: actionButtons(true))),
                gapMedium(),
                _buildCurrencySelections(context, constraints),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrencySelections(final BuildContext context, final BoxConstraints constraints) {
    final bool smallDevice = constraints.maxWidth < 500;

    // this feature is only valid for SubView [Chart|Transaction]
    if (currencyChoices.isEmpty) {
      return const SizedBox();
    }

    if (currencyChoices.length == 1) {
      return buildCurrencyWidget(currencyChoices[0]);
    }

    return mySegmentSelector(
      context: context,
      segments: <ButtonSegment<int>>[
        ButtonSegment<int>(
          value: 0,
          label: smallDevice ? Text(currencyChoices[0]) : buildCurrencyWidget(currencyChoices[0]),
        ),
        ButtonSegment<int>(
          value: 1,
          label: smallDevice ? Text(currencyChoices[1]) : buildCurrencyWidget(currencyChoices[1]),
        ),
      ],
      selectedId: currencySelected,
      onSelectionChanged: (final int newSelection) {
        currentSelectionChanged(newSelection);
      },
    );
  }

  Widget _buildExpando() {
    return IconButton(
      key: Constants.keySidePanelExpando,
      onPressed: () {
        onExpanded(!isExpanded);
      },
      icon: Icon(isExpanded ? Icons.expand_more : Icons.expand_less),
      tooltip: 'Expand/Collapse panel',
    );
  }

  Widget _buildViewSelections(final BuildContext context, final BoxConstraints constraints) {
    if (sidePanelSupport.supportedSubViews.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool smallDevice = ThemeController.to.isDeviceWidthSmall.value;

    return mySegmentSelector(
      context: context,
      segments: <ButtonSegment<int>>[
        if (sidePanelSupport.supportedSubViews.contains(
          SidePanelSubViewEnum.details,
        ))
          ButtonSegment<int>(
            value: 0,
            label: smallDevice ? null : const Text('Details'),
            icon: const Icon(Icons.info_outline),
          ),
        if (sidePanelSupport.supportedSubViews.contains(
          SidePanelSubViewEnum.chart,
        ))
          ButtonSegment<int>(
            value: 1,
            label: smallDevice ? null : const Text('Chart'),
            icon: const Icon(Icons.bar_chart),
          ),
        if (sidePanelSupport.supportedSubViews.contains(
          SidePanelSubViewEnum.transactions,
        ))
          ButtonSegment<int>(
            value: 2,
            label: smallDevice ? null : const Text('Transactions'),
            icon: const Icon(Icons.calendar_view_day),
          ),
        if (sidePanelSupport.supportedSubViews.contains(
          SidePanelSubViewEnum.pnl,
        ))
          ButtonSegment<int>(
            value: 3,
            label: smallDevice ? null : const Text('PnL'),
            icon: const Icon(Icons.calendar_view_day),
          ),
      ],
      selectedId: subViewSelected.index,
      onSelectionChanged: (final int newSelection) {
        if (!isExpanded) {
          onExpanded(true);
        }
        subViewSelectionChanged(SidePanelSubViewEnum.values[newSelection]);
      },
    );
  }
}
