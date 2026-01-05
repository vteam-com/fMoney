import 'package:flutter/widgets.dart';
import 'package:money/helpers/constants.dart';

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
