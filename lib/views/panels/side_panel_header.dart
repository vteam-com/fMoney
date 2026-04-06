import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/views/panels/side_panel_support.dart';
import 'package:money/widgets/components/my_segment.dart';
import 'package:money/widgets/pure/gaps.dart';
import 'package:money/widgets/state/theme_controller.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const double _headerHorizontalPadding = 4.0;
const double _smallDeviceMaxWidth = 500.0;
const int _currencyIndexPrimary = 0;
const int _currencyIndexSecondary = 1;
const int _subViewIndexDetails = 0;
const int _subViewIndexChart = 1;
const int _subViewIndexTransactions = 2;
const int _subViewIndexPnl = 3;

/// A stateless widget for side panel header.
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
            padding: const EdgeInsets.symmetric(horizontal: _headerHorizontalPadding),
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

  /// Builds the currency selector used by side panel chart/transaction subviews.
  Widget _buildCurrencySelections(final BuildContext context, final BoxConstraints constraints) {
    final bool smallDevice = constraints.maxWidth < _smallDeviceMaxWidth;

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
          value: _currencyIndexPrimary,
          label: smallDevice
              ? Text(currencyChoices[_currencyIndexPrimary])
              : buildCurrencyWidget(currencyChoices[_currencyIndexPrimary]),
        ),
        ButtonSegment<int>(
          value: _currencyIndexSecondary,
          label: smallDevice
              ? Text(currencyChoices[_currencyIndexSecondary])
              : buildCurrencyWidget(currencyChoices[_currencyIndexSecondary]),
        ),
      ],
      selectedId: currencySelected,
      onSelectionChanged: (final int newSelection) {
        currentSelectionChanged(newSelection);
      },
    );
  }

  /// Builds the expand/collapse button for the side panel.
  Widget _buildExpando() {
    return IconButton(
      key: Constants.keySidePanelExpando,
      onPressed: () {
        onExpanded(!isExpanded);
      },
      icon: Icon(isExpanded ? Icons.expand_more : Icons.expand_less),
      tooltip: AppL10n.tr(AppTranslationKeys.sidePanelExpandCollapseTooltip),
    );
  }

  /// Builds the segmented selector used to switch between supported side panel subviews.
  Widget _buildViewSelections(final BuildContext context, final BoxConstraints _) {
    if (sidePanelSupport.supportedSubViews.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool smallDevice = ThemeController.to.isDeviceWidthSmall;

    return mySegmentSelector(
      context: context,
      segments: <ButtonSegment<int>>[
        if (sidePanelSupport.supportedSubViews.contains(
          SidePanelSubViewEnum.details,
        ))
          ButtonSegment<int>(
            value: _subViewIndexDetails,
            label: smallDevice ? null : Text(AppL10n.tr(AppTranslationKeys.details)),
            icon: const Icon(Icons.info_outline),
          ),
        if (sidePanelSupport.supportedSubViews.contains(
          SidePanelSubViewEnum.chart,
        ))
          ButtonSegment<int>(
            value: _subViewIndexChart,
            label: smallDevice ? null : Text(AppL10n.tr(AppTranslationKeys.chart)),
            icon: const Icon(Icons.bar_chart),
          ),
        if (sidePanelSupport.supportedSubViews.contains(
          SidePanelSubViewEnum.transactions,
        ))
          ButtonSegment<int>(
            value: _subViewIndexTransactions,
            label: smallDevice ? null : Text(AppL10n.tr(AppTranslationKeys.transactions)),
            icon: const Icon(Icons.calendar_view_day),
          ),
        if (sidePanelSupport.supportedSubViews.contains(
          SidePanelSubViewEnum.pnl,
        ))
          ButtonSegment<int>(
            value: _subViewIndexPnl,
            label: smallDevice ? null : Text(AppL10n.tr(AppTranslationKeys.pnl)),
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
