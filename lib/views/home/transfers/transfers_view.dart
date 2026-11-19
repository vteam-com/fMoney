import 'package:collection/collection.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/potential_transfer_match_service.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transactions_collection.dart';
import 'package:money/shared/domain/transfer_entity.dart';
import 'package:money/shared/presentation/entity_widgets/potential_transfer_sheet_helper.dart';
import 'package:money/views/panels/cards/transfer_sender_receiver_card.dart';
import 'package:money/views/panels/layout/side_panel_support_model.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/widgets/pure/center_message_widget.dart';
import 'package:money/widgets/state/preferences_controller.dart';

const int _potentialTransferPausePollMilliseconds = 100;
const int _badgeLimit = 99;
const double _potentialTransferSuggestionListGap = 8;

/// Widget for displaying transfers between accounts.
class ViewTransfers extends ViewForMoneyObjects {
  /// Creates a new instance of [ViewTransfers].
  const ViewTransfers({super.key});

  @override
  State<ViewForMoneyObjects> createState() => _ViewTransfersState();
}

/// State class for [ViewTransfers].
class _ViewTransfersState extends ViewForMoneyObjectsState {
  /// Creates a new instance of [_ViewTransfersState].
  _ViewTransfersState() {
    viewId = ViewId.viewTransfers;
  }

  int _potentialTransferMatchCount = 0;
  bool _isPotentialTransferSheetOpen = false;
  bool _includeClosedAccountsInFinder = false;
  int _potentialTransferScanProgressTotal = 0;
  StateSetter? _potentialTransferSheetSetState;
  List<Transfer> _cachedSuggestions = <Transfer>[];

  @override
  String getClassNamePlural() {
    return AppL10n.tr(AppTranslationKeys.transfers);
  }

  @override
  String getClassNameSingular() {
    return AppL10n.tr(AppTranslationKeys.transfer);
  }

  @override
  String getDescription() {
    return AppL10n.tr(AppTranslationKeys.transfersBetweenAccountsDescription);
  }

  @override
  List<Widget> getActionsButtons(bool forSidePanelTransactions) {
    final List<Widget> widgets = super.getActionsButtons(forSidePanelTransactions);
    if (!forSidePanelTransactions) {
      widgets.add(_buildMagicWandButton());
    }
    return widgets;
  }

  @override
  Fields<Transfer> getFieldsForTable() {
    return Transfer.fieldsForColumnView;
  }

  @override
  List<Transfer> getList({
    bool includeDeleted = false,
    bool applyFilter = true,
  }) {
    List<Transfer> listOfTransfers = <Transfer>[];

    // Retrieve all transactions related to transfers.
    final List<Transaction> listOfTransactionsUseForTransfer = Data().transactions
        .getListFlattenSplits()
        .where(
          (Transaction transaction) => transaction.fieldTransfer.value != -1,
        )
        .toList();

    // Process sender transactions.
    for (final Transaction transactionOfSender in listOfTransactionsUseForTransfer) {
      // Identify sender transactions by negative amount.
      if (transactionOfSender.fieldAmount.value.asDouble() <= 0) {
        final Transaction? transactionOfReceiver = Data().transactions.get(
          transactionOfSender.fieldTransfer.value,
        );
        _addTransferToList(
          list: listOfTransfers,
          transactionSender: transactionOfSender,
          transactionReceiver: transactionOfReceiver,
          isOrphan: false,
        );
      }
    }

    // Process receiver transactions not already included.
    for (final Transaction transactionOfReceiver in listOfTransactionsUseForTransfer) {
      // Identify receiver transactions by positive amount.
      if (transactionOfReceiver.fieldAmount.value.asDouble() > 0) {
        final Transaction? transactionOfSender = Data().transactions.get(
          transactionOfReceiver.fieldTransfer.value,
        );
        if (transactionOfSender == null) {
          // Handle orphaned receiver transactions (sender not found).
          if (transactionOfReceiver.fieldTransferSplit.value != -1) {
            logger.i('This is a split'); // Log split transactions.
          }
          // Log the missing sender; without it there is no Transfer to list.
          logger.e(
            'related account not found ${transactionOfReceiver.uniqueId} ${transactionOfReceiver.fieldAmount.value}',
          );
        }
      }
    }

    // Apply filters if enabled.
    if (applyFilter) {
      listOfTransfers = listOfTransfers.where((Transfer instance) => isMatchingFilters(instance)).toList();
    }

    return listOfTransfers;
  }

  @override
  SidePanelSupport getSidePanelSupport() {
    return SidePanelSupport(onDetails: _getSidePanelViewDetails);
  }

  /// Adds a transfer to the list if the accounts are available and not excluded by filters.
  void _addTransferToList({
    required List<Transfer> list,
    required Transaction transactionSender,
    required Transaction? transactionReceiver,
    required bool isOrphan,
  }) {
    final Account? accountSender = transactionSender.instanceOfAccount;
    final Account? accountReceiver = transactionReceiver?.instanceOfAccount;

    if (accountSender != null && accountReceiver != null) {
      // Exclude closed accounts if the preference is set.
      if (accountSender.isClosed() && accountReceiver.isClosed() && !PreferenceController.to.includeClosedAccounts) {
        return;
      }

      final Transfer transfer = Transfer(
        id: 0,
        source: transactionSender,
        relatedTransaction: transactionReceiver,
        isOrphan: isOrphan,
      );
      list.add(transfer);
    }
  }

  /// Returns the side panel view details for a selected transfer.
  Widget _getSidePanelViewDetails({
    required List<int> selectedIds,
  }) {
    if (selectedIds.isNotEmpty) {
      final int id = selectedIds.first;
      final Transfer? transfer = list.firstWhereOrNull((DataObject element) => element.uniqueId == id) as Transfer?;
      if (transfer != null) {
        return TransferSenderReceiver(transfer: transfer);
      }
    }
    return CenterMessage(message: AppL10n.tr(AppTranslationKeys.noItemSelected));
  }

  /// Scans for disconnected transaction pairs that look like transfers and shows them as suggestions.
  void _runTransferSuggestionScan() {
    if (!mounted) {
      return;
    }
    final List<Transaction> eligibleTransactions = Data().transactions
        .iterableList(includeDeleted: false)
        .where(
          (Transaction transaction) =>
              isTransferMatchEligible(transaction, includeClosedAccounts: _includeClosedAccountsInFinder),
        )
        .toList();
    final List<Transfer> suggestions = findPotentialTransferPairs(eligibleTransactions: eligibleTransactions);

    setState(() {
      _cachedSuggestions = suggestions;
      _potentialTransferMatchCount = suggestions.length;
      _potentialTransferScanProgressTotal = eligibleTransactions.length;
    });
    _refreshPotentialTransferSheet();
  }

  /// Updates transfer finder scope and rescans.
  void _setIncludeClosedAccountsInFinder(bool value) {
    if (_includeClosedAccountsInFinder == value) {
      return;
    }
    _includeClosedAccountsInFinder = value;
    _runTransferSuggestionScan();
  }

  /// Refreshes sheet-local state when the bottom sheet is currently visible.
  void _refreshPotentialTransferSheet() {
    final StateSetter? setPanelState = _potentialTransferSheetSetState;
    if (setPanelState != null) {
      setPanelState(() {});
    }
  }

  /// Builds the Magic Wand icon button with an optional badge counter.
  Widget _buildMagicWandButton() {
    final String tooltip = AppL10n.tr(AppTranslationKeys.findMissingTransfers);

    return Badge(
      isLabelVisible: _potentialTransferMatchCount > 0,
      label: Text(_getBadgeLabelText(_potentialTransferMatchCount)),
      child: IconButton(
        tooltip: tooltip,
        onPressed: _onMagicWandPressed,
        icon: const Icon(Icons.auto_fix_high),
      ),
    );
  }

  /// Builds text for the badge with an upper bound to keep the header compact.
  String _getBadgeLabelText(int count) {
    if (count > _badgeLimit) {
      return '$_badgeLimit+';
    }
    return '$count';
  }

  /// Opens suggestions panel and auto-starts the transfer suggestion scan.
  void _onMagicWandPressed() {
    if (_isPotentialTransferSheetOpen) {
      return;
    }

    _showTransferSuggestionsBottomSheet();
    if (_cachedSuggestions.isNotEmpty) {
      return;
    }
    // Auto-start the scan after the sheet's StatefulBuilder has initialized.
    // Use a small delay to allow the sheet UI to build and set up the state setter.
    Future<void>.delayed(
      const Duration(milliseconds: _potentialTransferPausePollMilliseconds),
      _runTransferSuggestionScan,
    );
  }

  /// Shows possible transfer suggestions with scan controls and conversion actions.
  void _showTransferSuggestionsBottomSheet() {
    _isPotentialTransferSheetOpen = true;

    showPotentialTransferSheet(
      context: context,
      builder: (BuildContext sheetContext, StateSetter setPanelState) {
        _potentialTransferSheetSetState = setPanelState;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: SizeForPadding.normal,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  flex: Constants.flex2x,
                  child: Text(
                    AppL10n.tr(AppTranslationKeys.possibleTransferMatches),
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: SwitchListTile.adaptive(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppL10n.tr(AppTranslationKeys.includeClosedAccountsInFinder)),
                    value: _includeClosedAccountsInFinder,
                    onChanged: _setIncludeClosedAccountsInFinder,
                  ),
                ),
              ],
            ),

            Text(_getTransferScanSummaryText()),

            Expanded(
              child: _cachedSuggestions.isEmpty
                  ? CenterMessage(message: AppL10n.tr(AppTranslationKeys.noMatchingTransactions))
                  : ListView.separated(
                      itemCount: _cachedSuggestions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: _potentialTransferSuggestionListGap),
                      itemBuilder: (BuildContext _, int index) {
                        final Transfer preview = _cachedSuggestions[index];
                        return buildPotentialTransferCard(
                          preview: preview,
                          previewWidget: TransferSenderReceiver(transfer: preview),
                          onConverted: () {
                            setState(() {
                              _cachedSuggestions.removeAt(index);
                              _potentialTransferMatchCount = _cachedSuggestions.length;
                            });
                            _refreshPotentialTransferSheet();

                            if (_cachedSuggestions.isEmpty) {
                              Navigator.of(sheetContext).pop();
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    ).whenComplete(() {
      _isPotentialTransferSheetOpen = false;
      _potentialTransferSheetSetState = null;
    });
  }

  /// Builds text for the scan progress row.
  /// Formats an integer with locale-specific thousand separators.
  String _formatNumber(int value) {
    final NumberFormat formatter = NumberFormat.decimalPattern();
    return formatter.format(value);
  }

  /// Builds text summarizing found candidates and scanned transactions.
  String _getTransferScanSummaryText() {
    return AppL10n.tr(
      AppTranslationKeys.transferScanSummary,
      params: <String, String>{
        'candidates': _formatNumber(_cachedSuggestions.length),
        'accounts': _formatNumber(_potentialTransferScanProgressTotal),
      },
    );
  }
}
