import 'package:money/data/helpers/investment_type_helper.dart';
import 'package:money/data/helpers/transaction_type_helper.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/investment_entity.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/shared/domain/transfer_entity.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/pickers/picker_panel.dart';
import 'package:money/widgets/pure/mutation_types.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';
import 'package:money/widgets/pure/theme_custom_model.dart';
import 'package:money/widgets/state/selection_controller.dart';
import 'package:money/widgets/widgets_domain/data_access_model.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';

const int _transactionUnsetId = -1;
const int _transactionZeroInt = 0;
const double _transactionZeroDouble = 0.0;
const double _potentialTransferHintIconSize = 14.0;
const double _potentialTransferHintIconButtonSize = 18.0;
const double _potentialTransferSheetHeaderPadding = 12.0;
const double _potentialTransferSheetMaxHeightFactor = 0.5;
const double _potentialTransferSheetMaxWidth = 900.0;
const int _potentialTransferSingleBestMatch = 1;
const double _potentialTransferPreviewCardSpacing = 16.0;
const double _potentialTransferPreviewCardPreferredWidth = 320.0;

/// Checks transfer linkage consistency and adds invalid transactions to [dangling].
void transactionCheckTransfers(
  dynamic transaction,
  Set<dynamic> dangling,
  List<dynamic> deletedAccounts,
) {
  keepUnused(deletedAccounts);
  if (transaction.fieldTransfer.value != _transactionUnsetId && transaction.instanceOfTransfer == null) {
    dangling.add(transaction);
  }

  if (transaction.instanceOfTransfer != null) {
    final dynamic other = transaction.instanceOfTransfer.relatedTransaction;
    if (other.isSplit as bool) {
      // Intentionally ignored: split transfer dangling auto-fix logic is not implemented.
    } else {
      if (other.instanceOfTransfer == null || other.instanceOfTransfer.relatedTransaction != transaction) {
        dangling.add(transaction);
      } else if (other.fieldTransfer.value != transaction.uniqueId) {
        dangling.add(transaction);
      }
    }
  }
}

/// Returns true when [transaction] contains a transfer to [account].
bool transactionContainsTransferTo(dynamic transaction, dynamic account) {
  if (transaction.isSplit as bool) {
    for (final TransactionSplit split in transaction.splits as List<TransactionSplit>) {
      if (split.fieldTransferId.value != _transactionUnsetId &&
          split.getTransferTransaction()?.fieldAccountId.value == account.uniqueId) {
        return true;
      }
    }
  }
  if (transaction.instanceOfTransfer != null &&
      transaction.instanceOfTransfer.relatedTransaction?.fieldAccountId.value == account.uniqueId) {
    return true;
  }
  return false;
}

/// Converts [nativeValue] into normalized currency using transaction account ratio.
double transactionGetNormalizedAmount(dynamic transaction, double nativeValue) {
  if (transaction.instanceOfAccount == null ||
      transaction.instanceOfAccount.getCurrencyRatio() == _transactionZeroDouble) {
    return nativeValue;
  }
  return nativeValue * (transaction.instanceOfAccount.getCurrencyRatio() as num).toDouble();
}

/// Returns existing investment for a transaction or creates a default one.
Investment transactionGetOrCreateInvestment(dynamic transaction) {
  transaction.instanceOfInvestment ??=
      DataAbstract.instance.getInvestment((transaction.uniqueId as num).toInt()) as Investment? ??
      Investment(
        id: (transaction.uniqueId as num).toInt(),
        security: _transactionUnsetId,
        unitPrice: _transactionZeroDouble,
        units: _transactionZeroDouble,
        investmentType: _transactionZeroInt,
        tradeType: _transactionZeroInt,
        data: DataAbstract.instance,
      );
  return transaction.instanceOfInvestment as Investment;
}

/// Returns payee text or transfer caption for [transaction].
String transactionGetPayeeOrTransferCaption(
  dynamic transaction, {
  required bool showAccount,
}) {
  final Investment? investment = transaction.instanceOfInvestment as Investment?;
  final double amount = transaction.fieldAmount.value.asDouble() as double;

  bool isFrom = false;
  String displayName = '';
  if (transaction.isTransfer as bool) {
    if (investment != null) {
      if (investment.fieldInvestmentType.value == InvestmentType.add.index) {
        isFrom = true;
      }
    } else if (amount > _transactionZeroDouble) {
      isFrom = true;
    }

    return transactionGetTransferCaption(
      transaction,
      transaction.instanceOfTransfer?.receiverAccount,
      isFrom,
      showAccount: showAccount,
    );
  } else {
    displayName = DataAbstract.instance.getPayeeName((transaction.fieldPayee.value as num).toInt());
  }
  return displayName.isEmpty ? SharedDomainStrings.domainString007 : displayName;
}

/// Builds transfer caption text for [transaction] and [relatedAccount].
String transactionGetTransferCaption(
  dynamic transaction,
  dynamic relatedAccount,
  bool isFrom, {
  required bool showAccount,
}) {
  String caption = showAccount ? transaction.accountName as String : SharedDomainStrings.domainString144;
  final String arrowDirection = isFrom ? ' <- ' : ' -> ';
  caption += arrowDirection;
  caption += transactionRelatedAccountName(relatedAccount);
  return caption;
}

/// Returns formatted account name for [relatedAccount].
String transactionRelatedAccountName(dynamic relatedAccount) {
  if (relatedAccount == null) {
    return SharedDomainStrings.domainString006;
  }
  String name = '';

  if (relatedAccount.isClosed() as bool) {
    name += 'Closed-Account: ';
  }
  return name + (relatedAccount.fieldName.value as String);
}

/// Stores original payee text if no original payee has been captured yet.
void transactionStashOriginalPayee(dynamic transaction) {
  if ((transaction.fieldOriginalPayee.value as String).isEmpty) {
    transaction.fieldOriginalPayee.value = transaction.getPayeeOrTransferCaption();
  }
}

/// Returns one-line description combining payee/transfer and category.
String transactionOneLinePayeeAndDescription(dynamic transaction) {
  String description = transaction.getPayeeOrTransferCaption(showAccount: true) as String;
  if ((transaction.categoryName as String).isNotEmpty) {
    description += ' | ${transaction.categoryName}';
  }
  return description;
}

/// Builds transaction status toggle widget.
Widget transactionBuildStatusButtonToggle(dynamic transaction) {
  return TextButton(
    style: OutlinedButton.styleFrom(
      padding: EdgeInsets.zero,
    ),
    child: Text(transactionStatusToLetter(transaction.fieldStatus.value as TransactionStatus)),
    onPressed: () {
      if (transaction.fieldStatus.value == TransactionStatus.reconciled) {
        SnackBarService.displayWarning(
          message: SharedDomainStrings.domainString114,
        );
        return;
      }
      if (transaction.fieldStatus.value == TransactionStatus.cleared) {
        if (transaction.valueBeforeEdit != null) {
          final int oldValue =
              (transaction.valueBeforeEdit[transaction.fieldStatus.name] ?? _transactionZeroInt) as int;
          transaction.fieldStatus.value = TransactionStatus.values[oldValue];

          if (transaction.mutation == MutationType.changed &&
              DataObject.isDataModified(transaction as DataObject) == false) {
            transaction.mutation = MutationType.none;
            DataAccess.trackMutations.increaseNumber(
              increaseChanged: _transactionUnsetId,
            );
          } else {
            DataAccess.trackMutations.setLastEditToNow();
          }
        }
      } else {
        transaction.mutateField(transaction.fieldStatus.name, TransactionStatus.cleared, false);
      }
      SelectionController.to.select(transaction.uniqueId as int);
    },
  );
}

/// Builds the Category cell widget for [transaction].
///
/// The common row (no pending suggestion to approve, category already set, no
/// splits to inspect) takes a fast path that skips the stateful suggestion
/// wrapper (animation controller, gesture handling) and the eager toString()
/// so list scrolling stays cheap, while keeping the same scale-down layout as
/// the wrapper.
Widget transactionBuildCategoryCellWidget(dynamic transaction) {
  final int effectiveCategoryId = transaction.possibleMatchingCategoryId == _transactionUnsetId
      ? transaction.fieldCategoryId.value as int
      : transaction.possibleMatchingCategoryId as int;
  final String categoryName = DataAbstract.instance.getCategoryNameFromId(
    effectiveCategoryId,
  );
  final Widget categoryWidget = DataAbstract.instance.getCategoryWidget(
    effectiveCategoryId,
  );

  if (transaction.possibleMatchingCategoryId == _transactionUnsetId &&
      transaction.fieldCategoryId.value != _transactionUnsetId &&
      transaction.isSplit == false) {
    return Row(
      children: <Widget>[
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: IntrinsicWidth(
              child: Tooltip(message: categoryName, child: categoryWidget),
            ),
          ),
        ),
      ],
    );
  }

  return DataAbstract.instance.categorySuggestionProvider.buildSuggestionWidget(
    onApproved: transaction.possibleMatchingCategoryId == _transactionUnsetId
        ? null
        : () {
            // record the change
            DataAbstract.instance.changeCategory(
              transaction,
              transaction.possibleMatchingCategoryId as int,
            );
          },
    onChooseCategory: transaction.fieldCategoryId.value == _transactionUnsetId
        ? (BuildContext context) {
            transaction.possibleMatchingCategoryId = _transactionUnsetId;
            showPopupSelection(
              title: SharedDomainStrings.domainString029,
              context: context,
              items: DataAbstract.instance.getCategoriesAsStrings(),
              selectedItem: '',
              onSelected: (String text) {
                DataAbstract.instance.changeCategoryFromCategoryName(transaction, text);
              },
            );
          }
        : null,
    isSplit: transaction.isSplit,
    transactionString: transaction.toString(),
    splits: transaction.splits,
    uniqueId: transaction.uniqueId,
    totalAmount: transaction.fieldAmount.value.asDouble(),
    child: Tooltip(message: categoryName, child: categoryWidget),
  ) as Widget;
}

/// Builds the Payee/Transfer cell widget and appends a transfer-hint icon when
/// disconnected transfer candidates are available for [transaction].
Widget transactionBuildPayeeOrTransferWidget(dynamic transaction) {
  final String caption = transaction.getPayeeOrTransferCaption() as String;
  final bool showHintIcon = _hasPotentialTransferMatch(transaction);

  return Row(
    children: <Widget>[
      Expanded(
        child: Text(
          caption,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      if (showHintIcon)
        Builder(
          builder: (BuildContext context) {
            final Color iconColor =
                Theme.of(context).extension<MoneyThemeData>()?.getColorForState(ColorState.warning) ?? Colors.orange;
            return IconButton(
              tooltip: AppL10n.tr(AppTranslationKeys.matchingTransaction),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(
                width: _potentialTransferHintIconButtonSize,
                height: _potentialTransferHintIconButtonSize,
              ),
              iconSize: _potentialTransferHintIconSize,
              color: iconColor,
              icon: const Icon(Icons.lightbulb_outline),
              onPressed: () => _showPotentialTransferMatchPanel(
                context,
                transaction,
              ),
            );
          },
        ),
    ],
  );
}

/// Returns true when [transaction] has at least one likely disconnected
/// counterpart that can be converted into a transfer.
///
/// Uses the cached per-data-version lookup so it stays cheap when called for
/// every row while scrolling.
bool _hasPotentialTransferMatch(dynamic transaction) {
  if (transaction.isDeleted as bool || transaction.isTransfer as bool || transaction.isSplit as bool) {
    return false;
  }
  return DataAbstract.instance.hasPotentialTransferMatch(transaction);
}

/// Opens a side-panel style bottom sheet using the transfer sender/receiver
/// cards and one primary action to convert two disconnected entries.
void _showPotentialTransferMatchPanel(
  BuildContext context,
  dynamic transaction,
) {
  final List<dynamic> matches = DataAbstract.instance.findPotentialTransferMatches(
    transaction: transaction,
    maxResults: _potentialTransferSingleBestMatch,
  );

  if (matches.isEmpty) {
    SnackBarService.displayWarning(
      message: AppL10n.tr(AppTranslationKeys.noMatchingTransactions),
    );
    return;
  }

  final dynamic bestMatch = matches.first;
  final Transfer previewTransfer = _buildPreviewTransfer(transaction, bestMatch);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    constraints: const BoxConstraints(
      maxWidth: _potentialTransferSheetMaxWidth,
    ),
    builder: (BuildContext dialogContext) {
      final double maxHeight = MediaQuery.of(dialogContext).size.height * _potentialTransferSheetMaxHeightFactor;
      return SafeArea(
        child: SizedBox(
          height: maxHeight,
          child: Column(
            spacing: SizeForPadding.normal,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(_potentialTransferSheetHeaderPadding),
                child: Text(
                  AppL10n.tr(AppTranslationKeys.matchingTransaction),
                  style: Theme.of(dialogContext).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _potentialTransferSheetHeaderPadding),
                child: DialogActionButton(
                  text: AppL10n.tr(AppTranslationKeys.recordATransferBetweenTwoAccounts),
                  onPressed: () {
                    final bool didConvert = DataAbstract.instance.convertDisconnectedTransactionsToTransfer(
                      transaction: transaction,
                      relatedTransaction: bestMatch,
                    );
                    if (didConvert) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _potentialTransferSheetHeaderPadding),
                  child: _buildTransferSenderReceiverPreview(previewTransfer),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Builds a side-panel style preview with sender and receiver cards.
Widget _buildTransferSenderReceiverPreview(Transfer transfer) {
  return SingleChildScrollView(
    child: Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: _potentialTransferPreviewCardSpacing,
        runSpacing: _potentialTransferPreviewCardSpacing,
        children: <Widget>[
          SizedBox(
            width: _potentialTransferPreviewCardPreferredWidth,
            child: _buildTransferPreviewObjectCard(
              title: AppL10n.tr(AppTranslationKeys.sender),
              transaction: transfer.source,
            ),
          ),
          SizedBox(
            width: _potentialTransferPreviewCardPreferredWidth,
            child: _buildTransferPreviewObjectCard(
              title: AppL10n.tr(AppTranslationKeys.receiver),
              transaction: transfer.relatedTransaction,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Builds sender/receiver preview using local card content to avoid
/// cross-layer dependencies from shared domain to shared presentation.
Widget _buildTransferPreviewObjectCard({
  required String title,
  required dynamic transaction,
}) {
  final DataObject? moneyObject = transaction as DataObject?;
  final List<Widget> details = moneyObject == null
      ? <Widget>[Text(AppL10n.tr(AppTranslationKeys.notFound))]
      : moneyObject.buildListOfNamesValuesWidgets(onEdit: null, compact: true);

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(_potentialTransferSheetHeaderPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: SizeForPadding.normal),
          ...details,
        ],
      ),
    ),
  );
}

/// Creates a temporary transfer model used only for sender/receiver preview UI.
Transfer _buildPreviewTransfer(dynamic transaction, dynamic relatedTransaction) {
  if ((transaction.fieldAmount.value.asDouble() as double) < _transactionZeroDouble) {
    return Transfer(
      id: _transactionZeroInt,
      source: transaction,
      relatedTransaction: relatedTransaction,
      isOrphan: false,
    );
  }
  return Transfer(
    id: _transactionZeroInt,
    source: relatedTransaction,
    relatedTransaction: transaction,
    isOrphan: false,
  );
}

/// Returns true when transaction category or split category matches any target.
bool transactionIsMatchingAnyOfTheseCategories(
  dynamic transaction,
  List<int> categoriesToMatch,
) {
  if (categoriesToMatch.contains(transaction.fieldCategoryId.value as int)) {
    return true;
  }
  if (transaction.isSplit as bool) {
    for (final TransactionSplit split in transaction.splits as List<TransactionSplit>) {
      if (categoriesToMatch.contains(split.fieldCategoryId.value)) {
        return true;
      }
    }
  }
  return false;
}

/// Lazily resolves and wires transfer linkage for a transaction.
Transfer? transactionResolveInstanceOfTransfer(dynamic transaction) {
  if (transaction.cachedTransfer == null && (transaction.isTransfer as bool)) {
    final dynamic relatedTransaction = DataAbstract.instance.getTransaction(
      transaction.fieldTransfer.value as int,
    );
    if (relatedTransaction != null) {
      transaction.cachedTransfer = Transfer(
        id: _transactionZeroInt,
        source: transaction,
        relatedTransaction: relatedTransaction,
        isOrphan: false,
      );
      relatedTransaction.cachedTransfer = Transfer(
        id: _transactionZeroInt,
        source: relatedTransaction,
        relatedTransaction: transaction,
        isOrphan: false,
      );
    }
  }
  return transaction.cachedTransfer as Transfer?;
}

/// Sorts transactions by date and uses ID as deterministic tie-breaker.
int transactionSortByDateTime(
  dynamic a,
  dynamic b,
  bool ascending,
) {
  int result = sortByDate(
    a.fieldDateTime.value as DateTime?,
    b.fieldDateTime.value as DateTime?,
    ascending,
  );
  if (result == _transactionZeroInt) {
    result = sortByValue(a.uniqueId as num, b.uniqueId as num, ascending);
  }
  return result;
}
