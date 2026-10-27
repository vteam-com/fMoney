import 'package:money/data/helpers/transaction_type_helper.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/payee_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transfer_entity.dart';
import 'package:money/shared/presentation/entity_widgets/category_widgets_helper.dart';
import 'package:money/shared/presentation/entity_widgets/entity_widget_providers_model.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/list/list_item_card.dart';
import 'package:money/widgets/pickers/category_picker_widget.dart';
import 'package:money/widgets/pickers/edit_box_date_picker_widget.dart';
import 'package:money/widgets/pickers/payee_or_transfer_picker_widget.dart';
import 'package:money/widgets/pickers/picker_panel.dart';
import 'package:money/widgets/pure/icon_button.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';
import 'package:money/widgets/pure/theme_custom_model.dart';
import 'package:money/widgets/state/selection_controller.dart';
import 'package:money/widgets/widgets_domain/data_access_model.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/data_object_widget_builders_model.dart';
import 'package:money/widgets/widgets_domain/data_object_widgets_helper.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const int _transactionUnsetId = -1;
const int _transactionZeroInt = 0;
const double _transactionZeroDouble = 0.0;
const double _transferPickerWidth = 300.0;
const double _transferPickerHeight = 80.0;
const double _potentialTransferHintIconSize = 14.0;
const double _potentialTransferHintIconButtonSize = 18.0;
const double _potentialTransferSheetHeaderPadding = 12.0;
const double _potentialTransferSheetMaxHeightFactor = 0.5;
const double _potentialTransferSheetMaxWidth = 900.0;
const int _potentialTransferSingleBestMatch = 1;
const double _potentialTransferPreviewCardSpacing = 16.0;
const double _potentialTransferPreviewCardPreferredWidth = 320.0;

/// Builders used by the potential-transfer preview cards, which only ever show transactions.
final DataObjectWidgetBuilders _transactionPreviewWidgetBuilders = DataObjectWidgetBuilders(
  buildFieldWidget: (DataObject instance, Field<dynamic> field) =>
      buildTransactionFieldDisplayWidget(instance as Transaction, field),
  buildEditWidget: (DataObject _, Field<dynamic> _, void Function(bool) _) => null,
  buildSmallScreen: (DataObject instance) => buildTransactionSmallScreenWidget(instance as Transaction),
);

/// Returns the [Transaction]-specific display widget for [field], or null for the generic one.
Widget? buildTransactionFieldDisplayWidget(Transaction transaction, Field<dynamic> field) {
  if (field.isSameDefinition(transaction.fieldCategoryId)) {
    return transactionBuildCategoryCellWidget(transaction);
  }
  if (field.isSameDefinition(transaction.fieldCurrency)) {
    return buildCurrencyWidget(transaction.currency);
  }
  if (field.isSameDefinition(transaction.fieldPayee)) {
    return transactionBuildPayeeOrTransferWidget(transaction);
  }
  if (field.isSameDefinition(transaction.fieldStatus)) {
    return transactionBuildStatusButtonToggle(transaction);
  }
  return null;
}

/// Returns the [Transaction]-specific editor for [field], or null for the generic one.
Widget? buildTransactionFieldEditWidget(
  Transaction transaction,
  Field<dynamic> field,
  void Function(bool /* wasModified */) onEdited,
) {
  if (field.isSameDefinition(transaction.fieldCategoryId)) {
    return _buildCategoryEditWidget(transaction, onEdited);
  }
  if (field.isSameDefinition(transaction.fieldDateTime)) {
    return PickerEditBoxDate(
      key: Constants.keyDatePicker,
      initialValue: transaction.dateTimeAsString,
      onChanged: (String? newDateSelected) {
        if (newDateSelected != null) {
          transaction.fieldDateTime.value = attemptToGetDateFromText(
            newDateSelected,
          );
          onEdited(true);
        }
      },
    );
  }
  if (field.isSameDefinition(transaction.fieldPayee)) {
    return _buildPayeeOrTransferEditWidget(transaction, onEdited);
  }
  return null;
}

/// Builds the small-screen card for [transaction].
Widget buildTransactionSmallScreenWidget(Transaction transaction) {
  return MyListItemAsCard(
    leftTopAsString: transaction.payeeName,
    leftBottomAsString:
        '${DataAbstract.instance.getCategoryNameFromId(transaction.fieldCategoryId.value)}${SharedDomainStrings.domainString158}${transaction.fieldMemo.value}',
    rightTopAsWidget: WidgetFromData(
      amountModel: transaction.fieldAmount.value,
      size: DataWidgetSize.title,
    ),
    rightBottomAsString:
        '${transaction.dateTimeAsString}${SharedDomainStrings.domainString158}${DataAbstract.instance.getAccountName(transaction.fieldAccountId.value)}',
  );
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
Widget transactionBuildCategoryCellWidget(Transaction transaction) {
  final int effectiveCategoryId = transaction.possibleMatchingCategoryId == _transactionUnsetId
      ? transaction.fieldCategoryId.value
      : transaction.possibleMatchingCategoryId;
  final String categoryName = DataAbstract.instance.getCategoryNameFromId(
    effectiveCategoryId,
  );
  final Widget categoryWidget = buildCategoryWidgetFromId(
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

  return EntityWidgetProviders.categorySuggestion!.buildSuggestionWidget(
    onApproved: transaction.possibleMatchingCategoryId == _transactionUnsetId
        ? null
        : () {
            // record the change
            DataAbstract.instance.changeCategory(
              transaction,
              transaction.possibleMatchingCategoryId,
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
  );
}

/// Builds the Payee/Transfer cell widget and appends a transfer-hint icon when
/// disconnected transfer candidates are available for [transaction].
Widget transactionBuildPayeeOrTransferWidget(Transaction transaction) {
  final String caption = transaction.getPayeeOrTransferCaption();
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
            final Color iconColor = context.colorTheme.getColorForState(ColorState.warning);
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

/// Builds the category picker editor, with a split shortcut when [transaction] is a split.
Widget _buildCategoryEditWidget(Transaction transaction, void Function(bool /* wasModified */) onEdited) {
  return Row(
    children: <Widget>[
      Expanded(
        child: pickerCategory(
          key: const Key('key_pick_category'),
          categoryNames: DataAbstract.instance.getCategoriesAsStrings(),
          selectedName: DataAbstract.instance.getCategoryNameFromId(transaction.fieldCategoryId.value),
          onSelected: (String? name) {
            if (name != null) {
              DataAbstract.instance.changeCategoryFromCategoryName(transaction, name);
              onEdited(true);
            }
          },
        ),
      ),
      if (transaction.fieldCategoryId.value == DataAbstract.instance.getSplitCategoryId())
        MyIconButton(
          icon: Icons.arrow_forward_ios,
          onPressed: () {
            // Split editing is now handled by SuggestionApproval widget
            // when the category widget is tapped for split transactions
          },
        ),
    ],
  );
}

/// Builds the payee-or-transfer picker editor for [transaction].
Widget _buildPayeeOrTransferEditWidget(Transaction transaction, void Function(bool /* wasModified */) onEdited) {
  return SizedBox(
    width: _transferPickerWidth,
    height: _transferPickerHeight,
    child: PickPayeeOrTransfer(
      choice: transaction.fieldTransfer.value == _transactionUnsetId
          ? TransactionFlavor.payee
          : TransactionFlavor.transfer,
      selectedPayeeName: DataAbstract.instance.getPayeeName(transaction.fieldPayee.value),
      selectedAccountName: transaction.instanceOfTransfer?.receiverAccount?.fieldName.value,
      amount: transaction.fieldAmount.value.asDouble(),
      payeeNames: DataAbstract.instance.getPayeeNamesSorted(),
      accountNames: DataAbstract.instance.getAccountNamesSorted(),
      onSelected:
          (
            TransactionFlavor choice,
            String? selectedPayeeName,
            String? selectedAccountName,
          ) {
            bool wasModified = false;

            switch (choice) {
              case TransactionFlavor.payee:
                if (selectedPayeeName != null) {
                  final dynamic selectedPayee = DataAbstract.instance.getPayeeByName(selectedPayeeName);
                  if (selectedPayee != null) {
                    transaction.fieldPayee.value = (selectedPayee as dynamic).uniqueId as int;
                    transaction.fieldTransfer.value = _transactionUnsetId;
                    transaction.instanceOfTransfer = null;
                    wasModified = true;
                  }
                }
              case TransactionFlavor.transfer:
                // this is used to let the dialog Apply code what account should be
                // used when for transfer with.
                final dynamic transferAccount = selectedAccountName != null
                    ? DataAbstract.instance.getAccountByName(selectedAccountName)
                    : null;
                transaction.editingTransferAccount = transferAccount as Account?;
                transaction.fieldTransfer.value = _transactionUnsetId; // this will cause a reevaluation of the transfer

                if (transferAccount == null) {
                  // No account has been selected yet by the users
                  // do nothing since this is just the user taping between Payee | Transfer
                  transaction.fieldPayee.value = _transactionUnsetId;
                } else {
                  // mark as Transfer
                  transaction.fieldPayee.value = DataAbstract.instance.getTransferCategoryId();
                }
                wasModified = true;
            }
            onEdited(wasModified); // notify container
          },
      onMergePayee: (String payeeName, BuildContext context) {
        final Payee? payee = DataAbstract.instance.getPayeeByName(payeeName) as Payee?;
        if (payee != null) {
          final Iterable<Transaction> transactions = DataAbstract.instance
              .getTransactions(
                includeDeleted: true,
              )
              .cast<Transaction>()
              .where((Transaction t) => t.fieldPayee.value == payee.uniqueId);
          Navigator.of(context).pop(false);
          EntityWidgetProviders.mergePayee!.showMergePayee<Transaction>(
            context,
            payee,
            transactions,
            DataAbstract.instance,
          );
        }
      },
    ),
  );
}

/// Returns true when [transaction] has at least one likely disconnected
/// counterpart that can be converted into a transfer.
///
/// Uses the cached per-data-version lookup so it stays cheap when called for
/// every row while scrolling.
bool _hasPotentialTransferMatch(Transaction transaction) {
  if (transaction.isDeleted || transaction.isTransfer || transaction.isSplit) {
    return false;
  }
  return DataAbstract.instance.hasPotentialTransferMatch(transaction);
}

/// Opens a side-panel style bottom sheet using the transfer sender/receiver
/// cards and one primary action to convert two disconnected entries.
void _showPotentialTransferMatchPanel(
  BuildContext context,
  Transaction transaction,
) {
  final List<DataObject> matches = DataAbstract.instance.findPotentialTransferMatches(
    transaction: transaction,
    maxResults: _potentialTransferSingleBestMatch,
  );

  if (matches.isEmpty) {
    SnackBarService.displayWarning(
      message: AppL10n.tr(AppTranslationKeys.noMatchingTransactions),
    );
    return;
  }

  final Transaction bestMatch = matches.first as Transaction;
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

/// Builds sender/receiver preview using local card content.
Widget _buildTransferPreviewObjectCard({
  required String title,
  required dynamic transaction,
}) {
  final DataObject? moneyObject = transaction as DataObject?;
  final List<Widget> details = moneyObject == null
      ? <Widget>[Text(AppL10n.tr(AppTranslationKeys.notFound))]
      : buildListOfNamesValuesWidgets(
          moneyObject,
          builders: _transactionPreviewWidgetBuilders,
          onEdit: null,
          compact: true,
        );

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
Transfer _buildPreviewTransfer(Transaction transaction, Transaction relatedTransaction) {
  if (transaction.fieldAmount.value.asDouble() < _transactionZeroDouble) {
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
