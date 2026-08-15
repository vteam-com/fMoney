import 'package:collection/collection.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transactions_collection.dart';
import 'package:money/shared/domain/transfer_entity.dart';
import 'package:money/views/panels/cards/transfer_sender_receiver_card.dart';
import 'package:money/views/panels/layout/side_panel_support_model.dart';
import 'package:money/views/panels/list/money_objects_view.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/pure/center_message_widget.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';

const int _unlinkedTransferId = -1;
const int _previewTransferId = 0;
const int _potentialTransferProgressUpdateFrequency = 512;
const int _potentialTransferPausePollMilliseconds = 100;
const int _potentialTransferMaxDays = 5;
const int _hoursPerDay = 24;
const int _millisecondsPerDay = Duration.millisecondsPerDay;
const int _amountBucketMultiplier = 100;
const int _initialBestDelta = 1 << 30;
const int _badgeLimit = 99;
const double _potentialTransferSheetMaxHeightFactor = 0.7;
const double _potentialTransferSheetMaxWidth = 1000;
const double _potentialTransferSuggestionListGap = 8;
const double _potentialTransferSheetBorderAlpha = 0.3;

/// Precomputed indexes used by the transfer suggestion scan.
class _TransferScanIndex {
  /// Creates a container for scan-time lookup maps.
  const _TransferScanIndex({
    required this.candidatesBySignDayAmount,
    required this.sameAccountOppositeIds,
  });

  /// Fast lookup of candidates grouped by sign -> day -> amount bucket.
  final Map<bool, Map<int, Map<int, List<Transaction>>>> candidatesBySignDayAmount;

  /// Transactions that already have a same-account opposite-side counterpart.
  final Set<int> sameAccountOppositeIds;
}

/// Represents one suggested pair of disconnected transactions to convert to transfer.
class _PotentialTransferSuggestion {
  /// Creates a transfer suggestion pair.
  const _PotentialTransferSuggestion({
    required this.transaction,
    required this.relatedTransaction,
  });

  /// The source transaction selected for transfer conversion.
  final Transaction transaction;

  /// The potential counterpart transaction selected for transfer conversion.
  final Transaction relatedTransaction;

  /// Builds a preview [Transfer] used by the existing sender/receiver card widget.
  Transfer toPreviewTransfer() {
    final bool transactionIsSender = transaction.fieldAmount.value.asDouble() <= 0;
    final Transaction sender = transactionIsSender ? transaction : relatedTransaction;
    final Transaction receiver = transactionIsSender ? relatedTransaction : transaction;
    return Transfer(
      id: _previewTransferId,
      source: sender,
      relatedTransaction: receiver,
      isOrphan: false,
    );
  }
}

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
  bool _isScanningPotentialTransfers = false;
  bool _cancelPotentialTransferScanRequested = false;
  bool _isPotentialTransferSheetOpen = false;
  bool _includeClosedAccountsInFinder = false;
  int _potentialTransferScanProgressTotal = 0;
  StateSetter? _potentialTransferSheetSetState;
  List<_PotentialTransferSuggestion> _cachedSuggestions = <_PotentialTransferSuggestion>[];

  @override
  void dispose() {
    _cancelPotentialTransferScanRequested = true;
    super.dispose();
  }

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
          logger.e(
            'related account not found ${transactionOfReceiver.uniqueId} ${transactionOfReceiver.fieldAmount.value}',
          ); // Log missing sender.
          _addTransferToList(
            list: listOfTransfers,
            transactionSender: transactionOfSender!, // Non-nullable, but logged as error above.
            transactionReceiver: transactionOfReceiver,
            isOrphan: true,
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

  /// Runs a user-triggered transfer suggestion scan and updates visible progress.
  Future<void> _runTransferSuggestionScan() async {
    if (_isScanningPotentialTransfers) {
      return;
    }

    final bool includeClosedAccountsInFinder = _includeClosedAccountsInFinder;

    setState(() {
      _cachedSuggestions = <_PotentialTransferSuggestion>[];
      _potentialTransferMatchCount = 0;
      _isScanningPotentialTransfers = true;
      _cancelPotentialTransferScanRequested = false;
      _potentialTransferScanProgressTotal = 0;
    });
    _refreshPotentialTransferSheet();

    final List<_PotentialTransferSuggestion> suggestions = await _findPotentialTransferSuggestions(
      includeClosedAccounts: includeClosedAccountsInFinder,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _cachedSuggestions = suggestions;
      _potentialTransferMatchCount = suggestions.length;
      _isScanningPotentialTransfers = false;
    });
    _refreshPotentialTransferSheet();
  }

  /// Finds candidate disconnected transaction pairs that can become transfers.
  Future<List<_PotentialTransferSuggestion>> _findPotentialTransferSuggestions({
    required bool includeClosedAccounts,
  }) async {
    final List<Transaction> disconnectedTransactions = Data().transactions.iterableList(includeDeleted: false).where((
      Transaction transaction,
    ) {
      if (!includeClosedAccounts && _isTransactionInClosedAccount(transaction)) {
        return false;
      }
      return !transaction.isDeleted &&
          !transaction.isTransfer &&
          !transaction.isSplit &&
          transaction.fieldTransfer.value == _unlinkedTransferId;
    }).toList();

    final _TransferScanIndex scanIndex = _buildTransferScanIndex(disconnectedTransactions);
    final Set<int> sameAccountOppositeIds = scanIndex.sameAccountOppositeIds;
    final Set<int> alreadyPairedIds = <int>{};
    final Set<String> uniquePairs = <String>{};
    final List<_PotentialTransferSuggestion> suggestions = <_PotentialTransferSuggestion>[];

    if (mounted) {
      setState(() {
        _potentialTransferScanProgressTotal = disconnectedTransactions.length;
      });
      _refreshPotentialTransferSheet();
    }

    for (int i = 0; i < disconnectedTransactions.length; i++) {
      if (_cancelPotentialTransferScanRequested) {
        break;
      }

      final Transaction source = disconnectedTransactions[i];

      if (alreadyPairedIds.contains(source.uniqueId)) {
        continue;
      }
      if (sameAccountOppositeIds.contains(source.uniqueId)) {
        continue;
      }

      final List<Transaction> candidates = _collectOppositeCandidatesForSource(
        source: source,
        candidatesBySignDayAmount: scanIndex.candidatesBySignDayAmount,
      );
      final Transaction? selectedCandidate = _findBestCandidate(
        source: source,
        candidates: candidates,
        alreadyPairedIds: alreadyPairedIds,
        sameAccountOppositeIds: sameAccountOppositeIds,
      );

      if (selectedCandidate != null) {
        final int lowerId = source.uniqueId < selectedCandidate.uniqueId ? source.uniqueId : selectedCandidate.uniqueId;
        final int upperId = source.uniqueId > selectedCandidate.uniqueId ? source.uniqueId : selectedCandidate.uniqueId;
        final String pairKey = '$lowerId:$upperId';
        if (!uniquePairs.contains(pairKey)) {
          uniquePairs.add(pairKey);
          alreadyPairedIds.add(source.uniqueId);
          alreadyPairedIds.add(selectedCandidate.uniqueId);
          suggestions.add(
            _PotentialTransferSuggestion(
              transaction: source,
              relatedTransaction: selectedCandidate,
            ),
          );
        }
      }

      final bool shouldRefreshProgress =
          i == disconnectedTransactions.length - 1 || i % _potentialTransferProgressUpdateFrequency == 0;
      if (shouldRefreshProgress && mounted) {
        setState(() {
          _potentialTransferMatchCount = suggestions.length;
        });
        _refreshPotentialTransferSheet();
      }
    }

    if (mounted) {
      setState(() {
        _potentialTransferMatchCount = suggestions.length;
      });
      _refreshPotentialTransferSheet();
    }

    return suggestions;
  }

  /// Builds scan indexes in one pass, then computes same-account exclusions.
  _TransferScanIndex _buildTransferScanIndex(List<Transaction> transactions) {
    final Map<bool, Map<int, Map<int, List<Transaction>>>> candidatesBySignDayAmount =
        <bool, Map<int, Map<int, List<Transaction>>>>{};
    final Map<int, Map<bool, Map<int, Map<int, List<Transaction>>>>> byAccountSignDayAmount =
        <int, Map<bool, Map<int, Map<int, List<Transaction>>>>>{};

    for (final Transaction transaction in transactions) {
      final DateTime? dateValue = transaction.fieldDateTime.value;
      if (dateValue == null) {
        continue;
      }

      final double amount = transaction.fieldAmount.value.asDouble();
      final bool isPositive = amount.isNegative == false;
      final int dayKey = dateValue.startOfDay.millisecondsSinceEpoch ~/ _millisecondsPerDay;
      final int amountBucket = _toAmountBucket(amount);

      final Map<int, Map<int, List<Transaction>>> signIndex = candidatesBySignDayAmount.putIfAbsent(
        isPositive,
        () => <int, Map<int, List<Transaction>>>{},
      );
      final Map<int, List<Transaction>> dayIndex = signIndex.putIfAbsent(dayKey, () => <int, List<Transaction>>{});
      final List<Transaction> candidateBucket = dayIndex.putIfAbsent(amountBucket, () => <Transaction>[]);
      candidateBucket.add(transaction);

      final int accountId = transaction.fieldAccountId.value;
      final Map<bool, Map<int, Map<int, List<Transaction>>>> accountIndex = byAccountSignDayAmount.putIfAbsent(
        accountId,
        () => <bool, Map<int, Map<int, List<Transaction>>>>{},
      );
      final Map<int, Map<int, List<Transaction>>> accountSignIndex = accountIndex.putIfAbsent(
        isPositive,
        () => <int, Map<int, List<Transaction>>>{},
      );
      final Map<int, List<Transaction>> accountDayIndex = accountSignIndex.putIfAbsent(
        dayKey,
        () => <int, List<Transaction>>{},
      );
      final List<Transaction> accountBucket = accountDayIndex.putIfAbsent(amountBucket, () => <Transaction>[]);
      accountBucket.add(transaction);
    }

    final Set<int> sameAccountOppositeIds = _buildSameAccountOppositeIds(
      transactions: transactions,
      byAccountSignDayAmount: byAccountSignDayAmount,
    );

    return _TransferScanIndex(
      candidatesBySignDayAmount: candidatesBySignDayAmount,
      sameAccountOppositeIds: sameAccountOppositeIds,
    );
  }

  /// Collects opposite-sign candidates for [source] from nearby days.
  List<Transaction> _collectOppositeCandidatesForSource({
    required Transaction source,
    required Map<bool, Map<int, Map<int, List<Transaction>>>> candidatesBySignDayAmount,
  }) {
    final DateTime? sourceDateValue = source.fieldDateTime.value;
    if (sourceDateValue == null) {
      return <Transaction>[];
    }

    final double sourceAmount = source.fieldAmount.value.asDouble();
    final bool sourceIsPositive = sourceAmount.isNegative == false;
    final int sourceDayKey = sourceDateValue.startOfDay.millisecondsSinceEpoch ~/ _millisecondsPerDay;
    final int sourceAmountBucket = _toAmountBucket(sourceAmount);

    final Map<int, Map<int, List<Transaction>>>? oppositeSignIndex = candidatesBySignDayAmount[!sourceIsPositive];
    if (oppositeSignIndex == null) {
      return <Transaction>[];
    }

    final List<Transaction> candidates = <Transaction>[];
    for (int day = sourceDayKey - _potentialTransferMaxDays; day <= sourceDayKey + _potentialTransferMaxDays; day++) {
      final Map<int, List<Transaction>>? dayIndex = oppositeSignIndex[day];
      if (dayIndex == null) {
        continue;
      }
      final List<Transaction>? bucket = dayIndex[sourceAmountBucket];
      if (bucket != null && bucket.isNotEmpty) {
        candidates.addAll(bucket);
      }
    }

    return candidates;
  }

  /// Returns transaction IDs that have an opposite-sign counterpart in same account.
  Set<int> _buildSameAccountOppositeIds({
    required List<Transaction> transactions,
    required Map<int, Map<bool, Map<int, Map<int, List<Transaction>>>>> byAccountSignDayAmount,
  }) {
    final Set<int> excludedIds = <int>{};

    for (final Transaction transaction in transactions) {
      final DateTime? dateValue = transaction.fieldDateTime.value;
      if (dateValue == null) {
        continue;
      }

      final double amount = transaction.fieldAmount.value.asDouble();
      final bool isPositive = amount.isNegative == false;
      final int dayKey = dateValue.startOfDay.millisecondsSinceEpoch ~/ _millisecondsPerDay;
      final int amountBucket = _toAmountBucket(amount);

      final Map<bool, Map<int, Map<int, List<Transaction>>>>? accountIndex =
          byAccountSignDayAmount[transaction.fieldAccountId.value];
      if (accountIndex == null) {
        continue;
      }

      final Map<int, Map<int, List<Transaction>>>? oppositeSignIndex = accountIndex[!isPositive];
      if (oppositeSignIndex == null) {
        continue;
      }

      bool foundMatch = false;
      for (
        int day = dayKey - _potentialTransferMaxDays;
        day <= dayKey + _potentialTransferMaxDays && !foundMatch;
        day++
      ) {
        final Map<int, List<Transaction>>? dayIndex = oppositeSignIndex[day];
        if (dayIndex == null) {
          continue;
        }

        final List<Transaction>? entries = dayIndex[amountBucket];
        if (entries == null) {
          continue;
        }

        for (final Transaction candidate in entries) {
          if (candidate.uniqueId == transaction.uniqueId) {
            continue;
          }
          if (_hasOppositeSign(amount, candidate.fieldAmount.value.asDouble())) {
            excludedIds.add(transaction.uniqueId);
            excludedIds.add(candidate.uniqueId);
            foundMatch = true;
            break;
          }
        }
      }
    }

    return excludedIds;
  }

  /// Finds the best candidate for [source] from [candidates] using date proximity.
  Transaction? _findBestCandidate({
    required Transaction source,
    required List<Transaction> candidates,
    required Set<int> alreadyPairedIds,
    required Set<int> sameAccountOppositeIds,
  }) {
    final DateTime? sourceDateValue = source.fieldDateTime.value;
    if (sourceDateValue == null) {
      return null;
    }

    final DateTime sourceDate = sourceDateValue.startOfDay;
    final int sourceAccountId = source.fieldAccountId.value;
    final double sourceAmount = source.fieldAmount.value.asDouble();

    Transaction? bestCandidate;
    int bestDelta = _initialBestDelta;

    for (final Transaction candidate in candidates) {
      if (candidate.uniqueId == source.uniqueId) {
        continue;
      }
      if (alreadyPairedIds.contains(candidate.uniqueId)) {
        continue;
      }
      if (sameAccountOppositeIds.contains(candidate.uniqueId)) {
        continue;
      }
      if (candidate.fieldAccountId.value == sourceAccountId) {
        continue;
      }

      // Skip obvious reimbursement/refund style pairs: one expense and one
      // income category (neither transfer nor split category).
      if (_isLikelyIncomeExpensePair(source, candidate)) {
        continue;
      }

      // Skip credit-card-charge + bank-deposit pairs: a purchase on a credit
      // card is not a transfer out; only bank(-) → credit(+) is valid.
      if (_isInvalidCreditCardDirection(source, candidate)) {
        continue;
      }

      final double candidateAmount = candidate.fieldAmount.value.asDouble();
      if (!_hasOppositeSign(sourceAmount, candidateAmount)) {
        continue;
      }

      final DateTime? candidateDateValue = candidate.fieldDateTime.value;
      if (candidateDateValue == null) {
        continue;
      }

      final int delta = _getDayDifference(sourceDate, candidateDateValue.startOfDay);
      if (delta > _potentialTransferMaxDays) {
        continue;
      }

      if (bestCandidate == null ||
          delta < bestDelta ||
          (delta == bestDelta && candidate.uniqueId > bestCandidate.uniqueId)) {
        bestCandidate = candidate;
        bestDelta = delta;
      }
    }

    return bestCandidate;
  }

  /// Converts an amount to an absolute cents bucket for fast grouping.
  int _toAmountBucket(double amount) {
    return (amount.abs() * _amountBucketMultiplier).round();
  }

  /// Returns true when both transactions are categorized as opposite
  /// income/expense entries, which are unlikely to be real transfers.
  bool _isLikelyIncomeExpensePair(Transaction a, Transaction b) {
    final int transferCategoryId = Data().categories.transfer.uniqueId;
    final int splitCategoryId = Data().categories.split.uniqueId;

    final int aCategoryId = a.fieldCategoryId.value;
    final int bCategoryId = b.fieldCategoryId.value;

    final bool aIsTransferLike = aCategoryId == transferCategoryId || aCategoryId == splitCategoryId;
    final bool bIsTransferLike = bCategoryId == transferCategoryId || bCategoryId == splitCategoryId;
    if (aIsTransferLike || bIsTransferLike) {
      return false;
    }

    final Category? aCategory = Data().categories.get(aCategoryId);
    final Category? bCategory = Data().categories.get(bCategoryId);
    if (aCategory == null || bCategory == null) {
      return false;
    }

    final bool aExpenseBIncome = aCategory.isExpense && bCategory.isIncome;
    final bool aIncomeBExpense = aCategory.isIncome && bCategory.isExpense;
    return aExpenseBIncome || aIncomeBExpense;
  }

  /// Returns true when amounts are opposite in sign and non-zero.
  bool _hasOppositeSign(double a, double b) {
    return a != 0 && b != 0 && ((a < 0 && b > 0) || (a > 0 && b < 0));
  }

  /// Returns true when [accountType] represents a credit/charge account.
  bool _isCreditAccountType(AccountType accountType) {
    return accountType == AccountType.credit || accountType == AccountType.creditLine;
  }

  /// Returns true when pairing [a] and [b] would result in a credit-card charge
  /// being presented as the "sender" of a bank deposit — an invalid direction.
  ///
  /// A legitimate credit-card payment goes bank(-) → credit(+).
  /// The invalid case is credit(-) paired with bank(+): the negative leg is a
  /// purchase, not a transfer out.
  bool _isInvalidCreditCardDirection(Transaction a, Transaction b) {
    final Account? accountA = a.instanceOfAccount;
    final Account? accountB = b.instanceOfAccount;
    if (accountA == null || accountB == null) {
      return false;
    }

    final double amountA = a.fieldAmount.value.asDouble();
    final double amountB = b.fieldAmount.value.asDouble();

    final bool aIsCreditNegative = _isCreditAccountType(accountA.fieldType.value) && amountA < 0;
    final bool bIsCreditNegative = _isCreditAccountType(accountB.fieldType.value) && amountB < 0;

    // credit(-) paired with non-credit(+): purchase paired with a deposit — not a transfer
    if (aIsCreditNegative && !_isCreditAccountType(accountB.fieldType.value) && amountB > 0) {
      return true;
    }
    if (bIsCreditNegative && !_isCreditAccountType(accountA.fieldType.value) && amountA > 0) {
      return true;
    }

    return false;
  }

  /// Returns absolute day difference between two dates.
  int _getDayDifference(DateTime first, DateTime second) {
    return (second.difference(first).inHours / _hoursPerDay).abs().round();
  }

  /// Returns true when [transaction] belongs to a closed account.
  bool _isTransactionInClosedAccount(Transaction transaction) {
    final Account? account = transaction.instanceOfAccount;
    return account != null && account.isClosed();
  }

  /// Updates transfer finder scope and invalidates cached suggestions.
  void _setIncludeClosedAccountsInFinder(bool value) {
    if (_isScanningPotentialTransfers || _includeClosedAccountsInFinder == value) {
      return;
    }

    setState(() {
      _includeClosedAccountsInFinder = value;
      _cachedSuggestions = <_PotentialTransferSuggestion>[];
      _potentialTransferMatchCount = 0;
      _potentialTransferScanProgressTotal = 0;
    });
    _refreshPotentialTransferSheet();
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
    if (_cachedSuggestions.isNotEmpty || _isScanningPotentialTransfers) {
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

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: _potentialTransferSheetMaxWidth),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(SizeForRadius.normal),
        ),
        side: BorderSide(
          color: getColorTheme(context).primary.withValues(alpha: _potentialTransferSheetBorderAlpha),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      isDismissible: true,
      builder: (BuildContext dialogContext) {
        final double maxHeight = MediaQuery.of(dialogContext).size.height * _potentialTransferSheetMaxHeightFactor;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setPanelState) {
            _potentialTransferSheetSetState = setPanelState;
            return SafeArea(
              child: SizedBox(
                height: maxHeight,
                child: Padding(
                  padding: const EdgeInsets.all(SizeForPadding.normal),
                  child: Column(
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
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Expanded(
                            child: SwitchListTile.adaptive(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(AppL10n.tr(AppTranslationKeys.includeClosedAccountsInFinder)),
                              value: _includeClosedAccountsInFinder,
                              onChanged: _isScanningPotentialTransfers ? null : _setIncludeClosedAccountsInFinder,
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
                                  final _PotentialTransferSuggestion suggestion = _cachedSuggestions[index];
                                  final Transfer preview = suggestion.toPreviewTransfer();

                                  return Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(SizeForPadding.medium),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          DialogActionButton(
                                            text: AppL10n.tr(
                                              AppTranslationKeys.recordATransferBetweenTwoAccounts,
                                            ),
                                            onPressed: () {
                                              final bool didConvert = Data().convertDisconnectedTransactionsToTransfer(
                                                transaction: suggestion.transaction,
                                                relatedTransaction: suggestion.relatedTransaction,
                                              );

                                              if (!didConvert) {
                                                return;
                                              }

                                              setState(() {
                                                _cachedSuggestions.removeAt(index);
                                                _potentialTransferMatchCount = _cachedSuggestions.length;
                                              });
                                              _refreshPotentialTransferSheet();

                                              if (_cachedSuggestions.isEmpty) {
                                                Navigator.of(dialogContext).pop();
                                              }
                                            },
                                          ),
                                          const SizedBox(height: _potentialTransferSuggestionListGap),
                                          TransferSenderReceiver(transfer: preview),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
