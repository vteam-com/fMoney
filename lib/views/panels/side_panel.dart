import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/views/panels/side_panel_header.dart';
import 'package:money/views/panels/side_panel_support.dart';
import 'package:money/widgets/state/preferences_controller.dart';

/// A stateful widget for side panel.
class SidePanel extends StatefulWidget {
  /// Constructor
  const SidePanel({
    required this.isExpanded,
    required this.onExpanded,
    required this.selectedItems,
    // sub-views
    required this.sidePanelSupport,
    required this.getCurrencyChoices,
    required this.currencySelected,
    required this.currencySelectionChanged, // Actions
    required this.getActionButtons,
    super.key,
  });

  final int currencySelected;

  final void Function(int) currencySelectionChanged;

  final List<Widget> Function(bool) getActionButtons;

  final List<String> Function(SidePanelSubViewEnum, List<int>) getCurrencyChoices;

  final bool isExpanded;

  final void Function(bool) onExpanded;

  final ValueNotifier<List<int>> selectedItems;

  final SidePanelSupport sidePanelSupport;

  @override
  State<SidePanel> createState() => _SidePanelState();
}

class _SidePanelState extends State<SidePanel> {
  @override
  Widget build(final BuildContext context) {
    final SidePanelSubViewEnum effectiveSubView = _getEffectiveSelectedSubView();
    _syncSelectedSubViewIfNeeded(effectiveSubView);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SizeForPadding.medium),
      decoration: BoxDecoration(
        color: getColorTheme(context).surfaceContainerHighest,
        border: Border(
          left: BorderSide(color: getColorTheme(context).outline),
          top: BorderSide(color: getColorTheme(context).outline),
          right: BorderSide(color: getColorTheme(context).outline),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(SizeForRadius.normal),
          topRight: Radius.circular(SizeForRadius.normal),
        ),
      ),
      child: ValueListenableBuilder<List<int>>(
        valueListenable: widget.selectedItems,
        builder:
            (
              final BuildContext _,
              final List<int> listOfSelectedItemIndex,
              final _,
            ) {
              return ListenableBuilder(
                listenable: PreferenceController.to,
                builder: (final BuildContext _, final Widget? _) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      SidePanelHeader(
                        isExpanded: widget.isExpanded,
                        onExpanded: widget.onExpanded,

                        // SubPanel
                        sidePanelSupport: widget.sidePanelSupport,
                        subViewSelected: effectiveSubView,
                        subViewSelectionChanged:
                            (
                              final SidePanelSubViewEnum selected,
                            ) {
                              PreferenceController.to.selectedSidePanelTabId = selected;
                            },

                        // Currency
                        currencyChoices: widget.getCurrencyChoices(
                          effectiveSubView,
                          listOfSelectedItemIndex,
                        ),
                        currencySelected: widget.currencySelected,
                        currentSelectionChanged: widget.currencySelectionChanged,

                        // Actions
                        actionButtons: widget.getActionButtons,
                      ),
                      if (widget.isExpanded)
                        Expanded(
                          child: widget.sidePanelSupport.getSidePanelContent(
                            effectiveSubView,
                            listOfSelectedItemIndex,
                          ),
                        ),
                    ],
                  );
                },
              );
            },
      ),
    );
  }

  /// Returns a supported side-panel tab for the current side panel.
  SidePanelSubViewEnum _getEffectiveSelectedSubView() {
    final SidePanelSubViewEnum selectedSubView = PreferenceController.to.selectedSidePanelTabId;
    if (widget.sidePanelSupport.supportedSubViews.contains(selectedSubView)) {
      return selectedSubView;
    }
    return SidePanelSubViewEnum.details;
  }

  /// Schedules persistence of the effective side-panel tab when needed.
  void _syncSelectedSubViewIfNeeded(final SidePanelSubViewEnum effectiveSubView) {
    if (PreferenceController.to.selectedSidePanelTabId == effectiveSubView) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (PreferenceController.to.selectedSidePanelTabId != effectiveSubView) {
        PreferenceController.to.selectedSidePanelTabId = effectiveSubView;
      }
    });
  }
}
