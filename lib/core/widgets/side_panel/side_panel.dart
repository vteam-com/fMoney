import 'package:money/core/helpers/color_helper.dart';
import 'package:money/core/widgets/side_panel/side_panel_header.dart';
import 'package:money/core/widgets/side_panel/side_panel_views_enum.dart';
import 'package:money/data/models/constants.dart';
import 'package:money/views/home/sub_views/adaptive_view/adaptive_list/transactions/list_view_transactions.dart';

class SidePanelSupport {
  SidePanelSupport({
    this.onDetails,
    this.onChart,
    this.onTransactions,
    this.onPnL,
    this.onCopyToClipboard,
  });

  late final List<SidePanelSubViewEnum> supportedSubViews = <SidePanelSubViewEnum>[
    if (onDetails != null) SidePanelSubViewEnum.details,
    if (onChart != null) SidePanelSubViewEnum.chart,
    if (onTransactions != null) SidePanelSubViewEnum.transactions,
    if (onPnL != null) SidePanelSubViewEnum.pnl,
  ];

  int selectedCurrency = 0;

  /// Details
  Widget Function({required List<int> selectedIds, required bool isReadOnly})? onDetails;

  /// Chart
  Widget Function({
    required List<int> selectedIds,
    required bool showAsNativeCurrency,
  })?
  onChart;

  /// Transactions
  Widget Function({
    required List<int> selectedIds,
    required bool showAsNativeCurrency,
  })?
  onTransactions;

  /// PnL
  Widget Function({
    required List<int> selectedIds,
    required bool showAsNativeCurrency,
  })?
  onPnL;

  Function? onCopyToClipboard;

  Widget getSidePanelContent(
    final SidePanelSubViewEnum subViewId,
    final List<int> selectedIds,
  ) {
    switch (subViewId) {
      /// Details
      case SidePanelSubViewEnum.details:
        return onDetails!(selectedIds: selectedIds, isReadOnly: false);

      /// Chart
      case SidePanelSubViewEnum.chart:
        if (onChart == null) {
          return const Text('- empty -');
        }
        return onChart!(
          selectedIds: selectedIds,
          showAsNativeCurrency: selectedCurrency == 0,
        );

      /// PnL
      case SidePanelSubViewEnum.pnl:
        if (onPnL == null) {
          return const Text('- empty -');
        }
        return onPnL!(
          selectedIds: selectedIds,
          showAsNativeCurrency: selectedCurrency == 0,
        );

      /// Transactions
      case SidePanelSubViewEnum.transactions:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: onTransactions!(
            selectedIds: selectedIds,
            showAsNativeCurrency: selectedCurrency == 0,
          ),
        );
    }
  }
}

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
    if (!widget.sidePanelSupport.supportedSubViews.contains(
      PreferenceController.to.selectedSidePanelTabId,
    )) {
      PreferenceController.to.selectedSidePanelTabId = SidePanelSubViewEnum.details;
    }

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
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: ValueListenableBuilder<List<int>>(
        valueListenable: widget.selectedItems,
        builder:
            (
              final BuildContext context,
              final List<int> listOfSelectedItemIndex,
              final _,
            ) {
              return Obx(() {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    SidePanelHeader(
                      isExpanded: widget.isExpanded,
                      onExpanded: widget.onExpanded,

                      // SubPanel
                      sidePanelSupport: widget.sidePanelSupport,
                      subViewSelected: PreferenceController.to.selectedSidePanelTabId,
                      subViewSelectionChanged:
                          (
                            final SidePanelSubViewEnum selected,
                          ) {
                            PreferenceController.to.selectedSidePanelTabId = selected;
                          },

                      // Currency
                      currencyChoices: widget.getCurrencyChoices(
                        PreferenceController.to.selectedSidePanelTabId,
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
                          PreferenceController.to.selectedSidePanelTabId,
                          listOfSelectedItemIndex,
                        ),
                      ),
                  ],
                );
              });
            },
      ),
    );
  }
}
