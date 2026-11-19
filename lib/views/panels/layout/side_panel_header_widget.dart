import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/views/panels/layout/side_panel_sub_view_helper.dart';
import 'package:money/views/panels/layout/side_panel_support_model.dart';
import 'package:money/widgets/components/my_segment_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:money/widgets/state/theme_controller.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const double _headerHorizontalPadding = 4.0;
const double _smallDeviceMaxWidth = 500.0;
const int _currencyIndexPrimary = 0;
const int _currencyIndexSecondary = 1;

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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
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
  Widget _buildCurrencySelections(BuildContext context, BoxConstraints constraints) {
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
      onSelectionChanged: (int newSelection) {
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
  Widget _buildViewSelections(BuildContext context, BoxConstraints _) {
    if (sidePanelSupport.supportedSubViews.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool smallDevice = ThemeController.to.isDeviceWidthSmall;

    return mySegmentSelector(
      context: context,
      segments: <ButtonSegment<int>>[
        for (final SidePanelSubViewEnum subView in sidePanelSupport.supportedSubViews)
          ButtonSegment<int>(
            value: subView.index,
            label: smallDevice ? null : Text(AppL10n.tr(subView.labelKey)),
            icon: Icon(subView.iconData),
          ),
      ],
      selectedId: subViewSelected.index,
      onSelectionChanged: (int newSelection) {
        if (!isExpanded) {
          onExpanded(true);
        }
        subViewSelectionChanged(SidePanelSubViewEnum.values[newSelection]);
      },
    );
  }
}
