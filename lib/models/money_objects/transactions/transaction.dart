// Imports
import 'package:money/controller/data_controller.dart';
import 'package:money/controller/selection_controller.dart';
import 'package:money/data/data.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/models/money_objects/accounts/account.dart';
import 'package:money/models/money_objects/currencies/currency.dart';
import 'package:money/models/money_objects/investments/investment.dart';
import 'package:money/models/money_objects/investments/investment_types.dart';
import 'package:money/models/money_objects/investments/investments.dart';
import 'package:money/models/money_objects/payees/payee.dart';
import 'package:money/models/money_objects/splits/splits.dart';
import 'package:money/models/money_objects/transactions/transaction_types.dart';
import 'package:money/models/money_objects/transfers/transfer.dart';
import 'package:money/views/dialog/picker_edit_box_date.dart';
import 'package:money/views/dialog/picker_panel.dart';
import 'package:money/views/home/sub_views/adaptive_view/adaptive_list/list_item_card.dart';
import 'package:money/views/home/sub_views/adaptive_view/adaptive_list/transactions/popup_transaction_splits.dart';
import 'package:money/views/home/sub_views/view_categories/picker_category.dart';
import 'package:money/views/home/sub_views/view_payees/picker_payee_or_transfer.dart';
import 'package:money/widgets/icon_button.dart';
import 'package:money/widgets/snack_bar.dart';
import 'package:money/widgets/suggestion_approval.dart';

// Exports
export 'package:money/fields/fields.dart';
export 'package:money/models/money_objects/transactions/transaction_types.dart';

/// Main source of information for this App
/// All transactions are loaded in this class [Transaction] and [Split]
class Transaction extends MoneyObject {
  Transaction({
    final TransactionStatus status = TransactionStatus.none,
    final int accountId = -1,
    required final DateTime? date,
  }) {
    // assert(date != null);
    this.fieldAccountId.value = accountId;
    this.fieldDateTime.value = date;
    this.fieldStatus.value = status;
    this.fieldFlags.value = TransactionFlags.none.index;
  }

  factory Transaction.fromDateDescriptionAmount(
    final Account account,
    final DateTime date,
    final String description,
    final double amount,
  ) {
    final Payee? payee = Data().aliases.findOrCreateNewPayee(
      description,
      fireNotification: false,
    );

    final Transaction t = Transaction(date: date);
    t.fieldId.value = -1;
    t.fieldAccountId.value = account.fieldId.value;
    t.fieldPayee.value = payee == null ? -1 : payee.fieldId.value;
    t.fieldMemo.value = description;
    t.fieldAmount.value.setAmount(amount);
    return t;
  }

  factory Transaction.fromJSon(final MyJson json, final double runningBalance) {
    final Transaction t = Transaction(date: json.getDate('Date'));
    // 0 ID
    t.fieldId.value = json.getInt('Id', -1);
    // 1 Account ID
    t.fieldAccountId.value = json.getInt('Account', -1);
    t.instanceOfAccount = Data().accounts.get(t.fieldAccountId.value);
    // 3 Status
    t.fieldStatus.value = TransactionStatus.values[json.getInt('Status')];
    // 4 Payee ID
    t.fieldPayee.value = json.getInt('Payee', -1);
    // 5 Original Payee
    t.fieldOriginalPayee.value = json.getString('OriginalPayee');
    // 6 Category Id
    t.fieldCategoryId.value = json.getInt('Category', -1);
    // 7 Memo
    t.fieldMemo.value = json.getString('Memo');
    // 8 Number
    t.fieldNumber.value = json.getString('Number');
    // 9 Reconciled Date
    t.fieldReconciledDate.value = json.getDate('ReconciledDate');
    // 10 BudgetBalanceDate
    t.fieldBudgetBalanceDate.value = json.getDate('BudgetBalanceDate');
    // 11 Transfer
    t.fieldTransfer.value = json.getInt('Transfer', -1);
    // 12 FITID
    t.fieldFitid.value = json.getString('FITID');
    // 13 Flags
    t.fieldFlags.value = json.getInt('Flags');

    // 14 Amount
    t.fieldAmount.value.setAmount(json.getDouble('Amount'));
    // 15 Sales Tax
    t.fieldSalesTax.value.setAmount(json.getDouble('SalesTax'));
    // 16 Transfer Split
    t.fieldTransferSplit.value = json.getInt('TransferSplit', -1);
    // 17 Merge Date
    t.fieldMergeDate.value = json.getDate('MergeDate');

    // not serialized
    t.balance = runningBalance;

    return t;
  }

  /// Balance native
  double balance = 0;

  /// Account Id
  /// SQLite  1|Account|INT|1||0
  FieldInt fieldAccountId = FieldInt(
    type: FieldType.text,
    name: 'Account',
    serializeName: 'Account',
    align: TextAlign.left,
    footer: FooterType.count,
    defaultValue: -1,
    getValueForDisplay: (final MoneyObject instance) => Data().accounts.getNameFromId(
      (instance as Transaction).fieldAccountId.value,
    ),
    getValueForSerialization: (final MoneyObject instance) => (instance as Transaction).fieldAccountId.value,
    // setValue: (MoneyObject instance, dynamic newValue) => (instance as Transaction).fieldAccountId.value = newValue,
  );

  /// Amount
  /// 14|Amount|money|1||0
  FieldMoney fieldAmount = FieldMoney(
    name: columnIdAmount,
    serializeName: 'Amount',
    getValueForDisplay: (final MoneyObject instance) => MoneyModel(
      amount: (instance as Transaction).fieldAmount.value.asDouble(),
      iso4217: instance.currency,
    ),
    getValueForSerialization: (final MoneyObject instance) => (instance as Transaction).fieldAmount.value.asDouble(),
    setValue: (final MoneyObject instance, dynamic newValue) =>
        (instance as Transaction).fieldAmount.value.setAmount(newValue),
    sort: (final MoneyObject a, final MoneyObject b, final bool ascending) => sortByValue(
      (a as Transaction).fieldAmount.value.asDouble(),
      (b as Transaction).fieldAmount.value.asDouble(),
      ascending,
    ),
  );

  //------------------------------------------------------------------------
  // Not serialized
  // derived property used for display

  /// Amount Normalized to USD
  FieldMoney fieldAmountAsTextNormalized = FieldMoney(
    name: columnIdAmountNormalized,
    columnWidth: ColumnWidth.small,
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForDisplay: (final MoneyObject instance) => MoneyModel(
      amount: (instance as Transaction).getNormalizedAmount(
        instance.fieldAmount.value.asDouble(),
      ),
      iso4217: Constants.defaultCurrency,
    ),
    sort: (final MoneyObject a, final MoneyObject b, final bool ascending) => sortByValue(
      (a as Transaction).fieldAmount.value.asDouble(),
      (b as Transaction).fieldAmount.value.asDouble(),
      ascending,
    ),
  );

  /// Balance native
  FieldMoney fieldBalanceNative = FieldMoney(
    name: columnIdBalance,
    columnWidth: ColumnWidth.small,
    footer: FooterType.range,
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForDisplay: (final MoneyObject instance) => MoneyModel(
      amount: (instance as Transaction).balance,
      iso4217: instance.currency,
    ),
  );

  /// Balance Normalized to USD
  FieldMoney fieldBalanceNormalized = FieldMoney(
    name: 'Balance(USD)',
    columnWidth: ColumnWidth.small,
    footer: FooterType.range,
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForDisplay: (final MoneyObject instance) => MoneyModel(
      amount: (instance as Transaction).getNormalizedAmount(
        instance.balance,
      ),
      iso4217: Constants.defaultCurrency,
    ),
    sort: (final MoneyObject a, final MoneyObject b, final bool ascending) => sortByValue(
      (a as Transaction).balance,
      (b as Transaction).balance,
      ascending,
    ),
  );

  /// Budget Balance Date
  /// 10|BudgetBalanceDate|datetime|0||0
  FieldDate fieldBudgetBalanceDate = FieldDate(
    name: 'ReconciledDate',
    serializeName: 'ReconciledDate',
    getValueForDisplay: (final MoneyObject instance) => dateToIso8601OrDefaultString(
      (instance as Transaction).fieldBudgetBalanceDate.value,
    ),
    getValueForSerialization: (final MoneyObject instance) => dateToIso8601OrDefaultString(
      (instance as Transaction).fieldBudgetBalanceDate.value,
    ),
  );

  /// Category Id
  /// SQLite 6|Category|INT|0||0
  FieldInt fieldCategoryId = FieldInt(
    type: FieldType.widget,
    columnWidth: ColumnWidth.large,
    align: TextAlign.left,
    footer: FooterType.count,
    name: 'Category',
    serializeName: 'Category',
    defaultValue: -1,
    getValueForDisplay: (final MoneyObject instance) {
      final Transaction t = instance as Transaction;

      final int effectiveCategoryId = t.possibleMatchingCategoryId == -1
          ? t.fieldCategoryId.value
          : t.possibleMatchingCategoryId;
      final String categoryName = Data().categories.getNameFromId(
        effectiveCategoryId,
      );
      final Widget categoryWidget = Data().categories.getCategoryWidget(
        effectiveCategoryId,
      );

      return SuggestionApproval(
        onApproved: t.possibleMatchingCategoryId == -1
            ? null
            : () {
                // record the change
                changeCategory(t, t.possibleMatchingCategoryId);
              },
        onChooseCategory: t.fieldCategoryId.value == -1
            ? (final BuildContext context) {
                t.possibleMatchingCategoryId = -1;
                showPopupSelection(
                  title: 'Category',
                  context: context,
                  items: Data().categories.getCategoriesAsStrings(),
                  selectedItem: '',
                  onSelected: (final String text) {
                    final Category? selectedCategory = Data().categories.getByName(text);
                    if (selectedCategory != null) {
                      changeCategory(t, selectedCategory.uniqueId);
                    }
                  },
                );
              }
            : null,
        onShowSplit: t.isSplit ? () => showTransactionSplits(t) : null,
        child: Tooltip(message: categoryName, child: categoryWidget),
      );
    },
    getValueForReading: (final MoneyObject instance) => (instance as Transaction).categoryName,
    getValueForSerialization: (final MoneyObject instance) => (instance as Transaction).fieldCategoryId.value,
    sort: (final MoneyObject a, final MoneyObject b, final bool ascending) => sortByString(
      (a as Transaction).categoryName,
      (b as Transaction).categoryName,
      ascending,
    ),
    setValue: (final MoneyObject instance, dynamic newValue) =>
        (instance as Transaction).fieldCategoryId.value = newValue as int,
    getEditWidget:
        (
          final MoneyObject instance,
          void Function(bool wasModified) onEdited,
        ) {
          (instance as Transaction);
          return Row(
            children: <Widget>[
              Expanded(
                child: pickerCategory(
                  key: const Key('key_pick_category'),
                  itemSelected: Data().categories.get(
                    instance.fieldCategoryId.value,
                  ),
                  onSelected: (Category? newCategory) {
                    if (newCategory != null) {
                      instance.fieldCategoryId.value = newCategory.uniqueId;
                      // notify container
                      onEdited(true);
                    }
                  },
                ),
              ),
              if (instance.fieldCategoryId.value == Data().categories.splitCategoryId())
                MyIconButton(
                  icon: Icons.arrow_forward_ios,
                  onPressed: () {
                    showTransactionSplits(instance);
                  },
                ),
            ],
          );
        },
  );

  FieldString fieldCurrency = FieldString(
    type: FieldType.widget,
    name: 'Currency',
    align: TextAlign.center,
    columnWidth: ColumnWidth.tiny,
    footer: FooterType.count,
    getValueForReading: (final MoneyObject instance) => (instance as Transaction).currency,
    getValueForDisplay: (final MoneyObject instance) {
      return Currency.buildCurrencyWidget((instance as Transaction).currency);
    },
  );

  /// Date
  /// SQLite 2|Date|datetime|1||0
  FieldDate fieldDateTime = FieldDate(
    name: 'Date',
    serializeName: 'Date',
    getValueForDisplay: (final MoneyObject instance) => (instance as Transaction).fieldDateTime.value,
    getValueForSerialization: (final MoneyObject instance) =>
        dateToSqliteFormat((instance as Transaction).fieldDateTime.value),
    getEditWidget:
        (
          final MoneyObject instance,
          void Function(bool wasModified) onEdited,
        ) {
          return PickerEditBoxDate(
            key: Constants.keyDatePicker,
            initialValue: (instance as Transaction).dateTimeAsString,
            onChanged: (String? newDateSelected) {
              if (newDateSelected != null) {
                instance.fieldDateTime.value = attemptToGetDateFromText(
                  newDateSelected,
                );
                onEdited(true);
              }
            },
          );
        },
    setValue: (MoneyObject instance, dynamic newValue) =>
        (instance as Transaction).fieldDateTime.value = attemptToGetDateFromText(newValue as String),
    sort: (final MoneyObject a, final MoneyObject b, final bool ascending) =>
        sortByDateTime(a as Transaction, b as Transaction, ascending),
  );

  /// FITID
  /// 12|FITID|nchar(40)|0||0
  FieldString fieldFitid = FieldString(
    name: 'FITID',
    serializeName: 'FITID',
    getValueForDisplay: (final MoneyObject instance) => (instance as Transaction).fieldFitid.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as Transaction).fieldFitid.value,
  );

  /// Flags
  /// 13|Flags|INT|1||0
  FieldInt fieldFlags = FieldInt(
    name: 'Flags',
    serializeName: 'Flags',
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForDisplay: (final MoneyObject instance) => (instance as Transaction).fieldFlags.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as Transaction).fieldFlags.value,
  );

  /// ID
  /// SQLite  0|Id|bigint|0||1
  FieldId fieldId = FieldId(
    getValueForSerialization: (final MoneyObject instance) => (instance as Transaction).uniqueId,
  );

  /// Memo
  /// 7|Memo|nvarchar(255)|0||0
  FieldString fieldMemo = FieldString(
    name: 'Memo',
    serializeName: 'Memo',
    getValueForDisplay: (final MoneyObject instance) => (instance as Transaction).fieldMemo.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as Transaction).fieldMemo.value,
    setValue: (MoneyObject instance, dynamic newValue) =>
        (instance as Transaction).fieldMemo.value = newValue as String,
  );

  /// MergeDate
  /// 17|MergeDate|datetime|0||0
  FieldDate fieldMergeDate = FieldDate(
    name: 'Merge Date',
    serializeName: 'MergeDate',
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForSerialization: (final MoneyObject instance) => dateToIso8601OrDefaultString(
      (instance as Transaction).fieldMergeDate.value,
    ),
  );

  /// Number
  /// 8|Number|nchar(10)|0||0
  FieldString fieldNumber = FieldString(
    name: 'Ref',
    serializeName: 'Number',
    columnWidth: ColumnWidth.nano,
    getValueForDisplay: (final MoneyObject instance) => (instance as Transaction).fieldNumber.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as Transaction).fieldNumber.value,
  );

  /// OriginalPayee
  /// before auto-aliasing, helps with future merging.
  /// SQLite 5|OriginalPayee|nvarchar(255)|0||0
  FieldString fieldOriginalPayee = FieldString(
    name: 'Original Payee',
    serializeName: 'OriginalPayee',
    getValueForDisplay: (final MoneyObject instance) => (instance as Transaction).fieldOriginalPayee.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as Transaction).fieldOriginalPayee.value,
  );

  FieldString fieldPaidOn = FieldString(
    type: FieldType.text,
    name: columnIdPaidOn,
    align: TextAlign.right,
    columnWidth: ColumnWidth.tiny,
    footer: FooterType.none,
    getValueForDisplay: (final MoneyObject instance) {
      return (instance as Transaction).fieldPaidOn.value;
    },
  );

  /// Payee Id (displayed as Text name of the Payee)
  /// SQLite 4|Payee|INT|0||0
  FieldInt fieldPayee = FieldInt(
    name: 'Payee/Transfer',
    serializeName: 'Payee',
    defaultValue: -1,
    type: FieldType.text,
    footer: FooterType.count,
    align: TextAlign.left,
    columnWidth: ColumnWidth.largest,
    sort: (final MoneyObject a, final MoneyObject b, final bool ascending) => sortByString(
      (a as Transaction).payeeName,
      (b as Transaction).payeeName,
      ascending,
    ),
    getValueForDisplay: (final MoneyObject instance) {
      return (instance as Transaction).getPayeeOrTransferCaption();
    },
    getValueForSerialization: (final MoneyObject instance) => (instance as Transaction).fieldPayee.value,
    setValue: (MoneyObject instance, dynamic newValue) {
      instance = instance as Transaction;
      instance.stashOriginalPayee();
      if (newValue == -1 || newValue == Data().categories.transfer.uniqueId) {
        // -1 means no payee, this is a Transfer?
        // TODO - implement was solution given that the call back here only has one value use for the Payee ID
      } else {
        // Payee
        instance.fieldPayee.value = newValue as int; // Payee Id
        instance.fieldTransfer.value = -1;
        instance.instanceOfTransfer = null;
      }
    },
    getEditWidget:
        (
          MoneyObject instance,
          void Function(bool wasModified) onEdited,
        ) {
          return SizedBox(
            width: 300,
            height: 80,
            child: PickPayeeOrTransfer(
              choice: (instance as Transaction).fieldTransfer.value == -1
                  ? TransactionFlavor.payee
                  : TransactionFlavor.transfer,
              payee: Data().payees.get(instance.fieldPayee.value),
              account: instance.instanceOfTransfer?.receiverAccount,
              amount: instance.fieldAmount.value.asDouble(),
              onSelected:
                  (
                    TransactionFlavor choice,
                    Payee? selectedPayee,
                    Account? transferAccount,
                  ) {
                    bool wasModified = false;

                    switch (choice) {
                      case TransactionFlavor.payee:
                        if (selectedPayee != null) {
                          instance.fieldPayee.value = selectedPayee.uniqueId;
                          instance.fieldTransfer.value = -1;
                          instance.instanceOfTransfer = null;
                          wasModified = true;
                        }
                      case TransactionFlavor.transfer:
                        // this is used to let the dialog Apply code what account should be
                        // used when for transfer with.
                        instance.editingTransferAccount = transferAccount;
                        instance.fieldTransfer.value = -1; // this will cause a reevaluation of the transfer

                        if (transferAccount == null) {
                          // No account has been selected yet by the users
                          // do nothing since this is just the user taping between Payee | Transfer
                          instance.fieldPayee.value = -1;
                        } else {
                          // mark as Transfer
                          instance.fieldPayee.value = Data().categories.transfer.uniqueId;
                        }
                        wasModified = true;
                    }
                    onEdited(wasModified); // notify container
                  },
            ),
          );
        },
  );

  Account? editingTransferAccount;

  /// Reconciled Date
  /// 9|ReconciledDate|datetime|0||0
  FieldDate fieldReconciledDate = FieldDate(
    name: 'ReconciledDate',
    serializeName: 'ReconciledDate',
    getValueForDisplay: (final MoneyObject instance) => dateToIso8601OrDefaultString(
      (instance as Transaction).fieldReconciledDate.value,
    ),
    getValueForSerialization: (final MoneyObject instance) => dateToIso8601OrDefaultString(
      (instance as Transaction).fieldReconciledDate.value,
    ),
  );

  /// Sales Tax
  /// 15|SalesTax|money|0||0
  FieldMoney fieldSalesTax = FieldMoney(
    name: 'Sales Tax',
    serializeName: 'SalesTax',
    getValueForDisplay: (final MoneyObject instance) => (instance as Transaction).fieldSalesTax.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as Transaction).fieldSalesTax.value.asDouble(),
    sort: (final MoneyObject a, final MoneyObject b, final bool ascending) => sortByValue(
      (a as Transaction).fieldSalesTax.value.asDouble(),
      (b as Transaction).fieldSalesTax.value.asDouble(),
      ascending,
    ),
  );

  /// Status N | E | C | R
  /// SQLite 3|Status|INT|0||0
  Field<TransactionStatus> fieldStatus = Field<TransactionStatus>(
    type: FieldType.widget,
    align: TextAlign.center,
    columnWidth: ColumnWidth.tiny,
    defaultValue: TransactionStatus.none,
    useAsDetailPanels: defaultCallbackValueFalse,
    name: columnIdStatus,
    serializeName: 'Status',
    getValueForDisplay: (final MoneyObject instance) => (instance as Transaction)._buildStatusButtonToggle(),
    getValueForSerialization: (final MoneyObject instance) => (instance as Transaction).fieldStatus.value.index,
    setValue: (MoneyObject instance, dynamic newValue) =>
        (instance as Transaction).fieldStatus.value = newValue as TransactionStatus,
    sort: (final MoneyObject a, final MoneyObject b, final bool ascending) => sortByString(
      transactionStatusToLetter((a as Transaction).fieldStatus.value),
      transactionStatusToLetter((b as Transaction).fieldStatus.value),
      ascending,
    ),
  );

  /// Transfer
  /// 11|Transfer|bigint|0||0
  Field<int> fieldTransfer = Field<int>(
    name: 'Transfer',
    serializeName: 'Transfer',
    defaultValue: -1,
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForDisplay: (final MoneyObject instance) => (instance as Transaction).fieldTransfer.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as Transaction).fieldTransfer.value,
  );

  /// Transfer Split
  /// 16|TransferSplit|INT|0||0
  FieldInt fieldTransferSplit = FieldInt(
    name: 'TransferSplit',
    serializeName: 'TransferSplit',
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForDisplay: (final MoneyObject instance) => (instance as Transaction).fieldTransferSplit.value,
    getValueForSerialization: (final MoneyObject instance) => (instance as Transaction).fieldTransferSplit.value,
  );

  /// cache instances of related MoneyObjects
  Investment? instanceOfInvestment;

  int possibleMatchingCategoryId = -1;
  List<MoneySplit> splits = <MoneySplit>[];

  /// Instances of related MoneyObjects
  Account? _instanceOfAccount;

  // Instance of Transfer
  Transfer? _instanceOfTransfer;

  @override
  Widget buildFieldsAsWidgetForSmallScreen() {
    return MyListItemAsCard(
      leftTopAsString: payeeName,
      leftBottomAsString: '${Data().categories.getNameFromId(fieldCategoryId.value)}\n${fieldMemo.value}',
      rightTopAsWidget: MoneyWidget(
        amountModel: fieldAmount.value,
        size: MoneyWidgetSize.title,
      ),
      rightBottomAsString: '$dateTimeAsString\n${Account.getName(instanceOfAccount)}',
    );
  }

  // Fields for this instance
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  @override
  String getRepresentation() {
    return accountName;
  }

  @override
  MoneyObject rollup(List<MoneyObject> moneyObjectInstances) {
    if (moneyObjectInstances.isEmpty) {
      return Transaction(date: DateTime.now());
    }
    if (moneyObjectInstances.length == 1) {
      return moneyObjectInstances.first;
    }

    MyJson commonJson = moneyObjectInstances.first.getPersistableJSon();

    for (MoneyObject t in moneyObjectInstances.skip(1)) {
      commonJson = compareAndGenerateCommonJson(
        commonJson,
        t.getPersistableJSon(),
      );
    }
    return Transaction.fromJSon(commonJson, 0);
  }

  @override
  String toString() {
    return '$dateTimeAsString | $accountName | $oneLinePayeeAndDescription | $amountAsString';
  }

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(final int value) => fieldId.value = value;

  static final Fields<Transaction> _fields = Fields<Transaction>();

  String get accountName => instanceOfAccount?.fieldName.value ?? '<Account???>';

  String get amountAsString => fieldAmount.value.toString();

  Category? get category => Data().categories.get(this.fieldCategoryId.value);

  String get categoryName => Data().categories.getNameFromId(this.fieldCategoryId.value);

  static void changeCategory(Transaction t, final int categoryId) {
    // record the change
    t.stashValueBeforeEditing();

    // Make change
    t.fieldCategoryId.value = categoryId;
    t.possibleMatchingCategoryId = -1;

    // inform of changes
    Data().notifyMutationChanged(
      mutation: MutationType.changed,
      moneyObject: t,
      recalculateBalances: true,
    );
  }

  /// TODO - clean this up,
  void checkTransfers(
    Set<Transaction> dangling,
    List<Account> deletedAccounts,
  ) {
    if (fieldTransfer.value != -1 && this.instanceOfTransfer == null) {
      // transferInstance?.getReceiverAccount();
      // if (IsDeletedAccount(this.to, money, deletedAccounts)) {
      //   this.Category =
      //       this.Amount < 0 ? Data().categories.TransferToDeletedAccount : money.Categories.TransferFromDeletedAccount;
      //   this.to = null;
      // } else {
      dangling.add(this);
      // }
    }

    if (this.instanceOfTransfer != null) {
      final Transaction other = this.instanceOfTransfer!.relatedTransaction!;
      if (other.isSplit) {
        //       int count = 0;
        //       Split splitXfer = null;
        //
        //       for (Split s in other.splits.GetSplits()) {
        //         if (s.transfer != null) {
        //           if (splitXfer == null) {
        //             splitXfer = s;
        //           }
        //           if (s.transfer.Transaction == this) {
        //             count++;
        //           }
        //         }
        // }
        //
        //       if (count == 0) {
        //         if (other.transfer != null && other.transfer.transaction == this) {
        //           // Ok, well it could be that the transfer is the whole transaction, but then
        //           // one side was itemized. For example, you transfer 500 from one account to
        //           // another, then on the deposit side you want to record what that was for
        //           // by itemizing the $500 in a split.  If this is the case then it is not dangling.
        //         } else if (!this.AutoFixDandlingTransfer(splitXfer)) {
        //           added = true;
        //           dangling.add(this);
        //         }
        //       }
      } else {
        if (other.instanceOfTransfer == null || other.instanceOfTransfer?.relatedTransaction != this) {
          dangling.add(this);
        } else {
          // one last check, the other side also needs to be correctly setup as a transfer
          if (other.fieldTransfer.value != this.uniqueId) {
            dangling.add(this);
          }
        }
      }
    }
  }

  bool containsTransferTo(Account a) {
    if (this.isSplit) {
      for (MoneySplit s in this.splits) {
        if (s.fieldTransferId.value != -1 && s.getTransferTransaction()?.fieldAccountId.value == a.uniqueId) {
          return true;
        }
      }
    }
    if (this.instanceOfTransfer != null &&
        this.instanceOfTransfer?.relatedTransaction?.fieldAccountId.value == a.uniqueId) {
      return true;
    }
    return false;
  }

  String get currency {
    if (this.instanceOfAccount == null || this.instanceOfAccount!.fieldCurrency.value.isEmpty) {
      return Constants.defaultCurrency;
    }

    return this.instanceOfAccount!.fieldCurrency.value;
  }

  String get dateTimeAsString => dateToString(fieldDateTime.value);

  static Fields<Transaction> get fields {
    if (_fields.isEmpty) {
      final Transaction tmp = Transaction(date: DateTime.now());
      _fields.setDefinitions(<Field<dynamic>>[
        tmp.fieldId,
        tmp.fieldDateTime,
        tmp.fieldAccountId,
        tmp.fieldPayee,
        tmp.fieldOriginalPayee,
        tmp.fieldCategoryId,
        tmp.fieldMemo,
        tmp.fieldNumber,
        tmp.fieldReconciledDate,
        tmp.fieldBudgetBalanceDate,
        tmp.fieldTransfer,
        tmp.fieldStatus,
        tmp.fieldFitid,
        tmp.fieldFlags,
        tmp.fieldCurrency,
        tmp.fieldSalesTax,
        tmp.fieldTransferSplit,
        tmp.fieldMergeDate,
        tmp.fieldAmount,
        tmp.fieldAmountAsTextNormalized,
        tmp.fieldBalanceNative,
        tmp.fieldBalanceNormalized,
        tmp.fieldPaidOn,
      ]);
    }
    return _fields;
  }

  static Fields<Transaction> get fieldsForColumnView {
    final Transaction tmp = Transaction(date: DateTime.now());
    return Fields<Transaction>()..setDefinitions(<Field<dynamic>>[
      tmp.fieldDateTime,
      tmp.fieldAccountId,
      tmp.fieldNumber,
      tmp.fieldPayee,
      tmp.fieldCategoryId,
      tmp.fieldMemo,
      tmp.fieldStatus,
      tmp.fieldCurrency,
      tmp.fieldAmount,
      tmp.fieldAmountAsTextNormalized,
      tmp.fieldBalanceNormalized,
    ]);
  }

  static String getDefaultCurrency(final Account? account) {
    // Convert the value to USD
    if (account == null || account.getCurrencyRatio() == 0) {
      return Constants.defaultCurrency;
    }
    return account.fieldCurrency.value;
  }

  double getNormalizedAmount(double nativeValue) {
    // Convert the value to USD
    if (instanceOfAccount == null || instanceOfAccount?.getCurrencyRatio() == 0) {
      return nativeValue;
    }
    return nativeValue * instanceOfAccount!.getCurrencyRatio();
  }

  Investment? getOrCreateInvestment() {
    if (this.instanceOfInvestment == null) {
      this.instanceOfInvestment = Data().investments.get(this.uniqueId);
      if (this.instanceOfInvestment != null) {
        this.instanceOfInvestment!.transactionInstance = this;
      }
    }
    return this.instanceOfInvestment;
  }

  String getPayeeOrTransferCaption({final bool showAccount = false}) {
    final Investment? investment = instanceOfInvestment;
    final double amount = this.fieldAmount.value.asDouble();

    bool isFrom = false;
    String displayName = '';
    if (isTransfer) {
      if (investment != null) {
        if (investment.fieldInvestmentType.value == InvestmentType.add.index) {
          isFrom = true;
        }
      } else if (amount > 0) {
        isFrom = true;
      }

      return getTransferCaption(
        instanceOfTransfer?.receiverAccount,
        isFrom,
        showAccount: showAccount,
      );
    } else {
      displayName = Data().payees.getNameFromId(fieldPayee.value);
    }
    return displayName.isEmpty ? '<Payee???>' : displayName;
  }

  String getTransferCaption(
    final Account? relatedAccount,
    final bool isFrom, {
    final bool showAccount = false,
  }) {
    String caption = showAccount ? accountName : 'Transfer';
    final String arrowDirection = isFrom ? ' ← ' : ' → ';
    caption += arrowDirection;
    caption += relatedAccountName(relatedAccount);
    return caption;
  }

  Account? get instanceOfAccount {
    /// cache instances of related MoneyObjects
    _instanceOfAccount ??= Data().accounts.get(this.fieldAccountId.value);
    return _instanceOfAccount;
  }

  set instanceOfAccount(Account? value) {
    _instanceOfAccount = value;
  }

  Transfer? get instanceOfTransfer {
    if (_instanceOfTransfer == null && isTransfer) {
      final Transaction? relatedTransaction = Data().transactions.get(
        this.fieldTransfer.value,
      );
      if (relatedTransaction != null) {
        linkTransfer(this, relatedTransaction);
      }
    }
    return _instanceOfTransfer;
  }

  set instanceOfTransfer(Transfer? value) {
    _instanceOfTransfer = value;
  }

  bool get isAssetAccount => instanceOfAccount?.isAssetAccount ?? false;

  bool get isCandidateForBudget => this.fieldCategoryId.value != -1 && (this.isExpense || this.isIncome);

  bool get isExpense => category?.isExpense == true;

  bool get isIncome => category?.isIncome == true;

  bool isMatchingAnyOfTheseCategories(List<int> categoriesToMatch) {
    if (categoriesToMatch.contains(fieldCategoryId.value)) {
      return true;
    }

    if (this.isSplit) {
      for (final MoneySplit s in this.splits) {
        if (categoriesToMatch.contains(s.fieldCategoryId.value)) {
          return true;
        }
      }
    }
    return false;
  }

  bool get isSplit => this.splits.isNotEmpty;

  bool get isTransfer => fieldTransfer.value != -1;

  String get oneLinePayeeAndDescription {
    String description = this.getPayeeOrTransferCaption(showAccount: true);

    if (this.categoryName.isNotEmpty) {
      description += ' | ${this.categoryName}';
    }

    return description;
  }

  String get payeeName => Data().payees.getNameFromId(fieldPayee.value);

  /// Find all the objects referenced by this Transaction and wire them back up

  /// <param name="money">The owner</param>
  /// <param name="parent">The container</param>
  /// <param name="from">The account this transaction belongs to</param>
  /// <param name="duplicateTransfers">How to handle transfers.  In a cut/paste situation you want
  /// to create new transfer transactions (true), but in a XmlStore.Load situation we do not (false)</param>
  void postDeserializeFixup(bool duplicateTransfers) {
    // if (this.CategoryName != null)
    // {
    //   this.Category = money.Categories.GetOrCreateCategory(this.CategoryName, CategoryType.None);
    //   this.CategoryName = null;
    // }
    // if (from != null)
    // {
    //   this.Account = from;
    // }
    // else if (this.AccountName != null)
    // {
    //   this.Account = money.Accounts.FindAccount(this.AccountName);
    // }
    // this.AccountName = null;
    // if (this.PayeeName != null)
    // {
    //   this.Payee = money.Payees.FindPayee(this.PayeeName, true);
    //   this.PayeeName = null;
    // }
    //
    // // do not copy budgeting information outside of balancing the budget.
    // // (Note: setting IsBudgeted to false will screw up the budget balance).
    // this.flags &= ~TransactionFlags.Budgeted;
    //
    // if (duplicateTransfers)
    // {
    //   if (this.TransferName != null)
    //   {
    //     Account to = money.Accounts.FindAccount(this.TransferName);
    //     if (to == null)
    //     {
    //       to = money.Accounts.AddAccount(this.TransferName);
    //     }
    //     if (to != from)
    //     {
    //       money.Transfer(this, to);
    //       this.TransferName = null;
    //     }
    //   }
    // }
    // else if (this.TransferId != -1 && this.Transfer == null)
    // {
    //   Transaction other = money.Transactions.FindTransactionById(this.transferId);
    //   if (this.TransferSplit != -1)
    //   {
    //     // then the other side of this is a split.
    //     Split s = other.NonNullSplits.FindSplit(this.TransferSplit);
    //     if (s != null)
    //     {
    //       s.Transaction = other;
    //       this.Transfer = new Transfer(0, this, other, s);
    //       s.Transfer = new Transfer(0, other, s, this);
    //     }
    //   }
    //   else if (other != null)
    //   {
    //     this.Transfer = new Transfer(0, this, other);
    //     other.Transfer = new Transfer(0, other, this);
    //   }
    // }
    //
    // if (this.Investment != null)
    // {
    //   this.Investment.Parent = parent;
    //   this.Investment.Transaction = this;
    //   if (this.Investment.SecurityName != null)
    //   {
    //     this.Investment.Security = money.Securities.FindSecurity(this.Investment.SecurityName, true);
    //   }
    // }
    // if (this.categoryId == Data().categories.splitCategoryId()) {
    //   Data().this.Splits.Transaction = this;
    //   this.Splits.Parent = this;
    //   foreach (Split s in this.Splits.Items)
    //   {
    //     s.PostDeserializeFixup(money, this, duplicateTransfers);
    //   }
    // }
  }

  Account? get relatedAccount => instanceOfTransfer?.relatedTransaction?.instanceOfAccount;

  String relatedAccountName(Account? relatedAccount) {
    if (relatedAccount == null) {
      return '<Account???>';
    }
    String name = '';

    if (relatedAccount.isClosed()) {
      name += 'Closed-Account: ';
    }
    return name + relatedAccount.fieldName.value;
  }

  static int sortByDateTime(
    final Transaction a,
    final Transaction b,
    final bool ascending,
  ) {
    int result = sortByDate(
      a.fieldDateTime.value,
      b.fieldDateTime.value!,
      ascending,
    );
    // To ensure a predictable sort order, always include a tie-breaker
    if (result == 0) {
      result = sortByValue(a.uniqueId, b.uniqueId, ascending);
    }
    return result;
  }

  /// keep track of the original Payee information, only do this if the originalPayee info is empty
  void stashOriginalPayee() {
    if (this.fieldOriginalPayee.value.isEmpty) {
      this.fieldOriginalPayee.value = this.getPayeeOrTransferCaption();
    }
  }

  Widget _buildStatusButtonToggle() {
    return TextButton(
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.zero, // Remove all padding
      ),
      child: Text(transactionStatusToLetter(this.fieldStatus.value)),
      onPressed: () {
        if (this.fieldStatus.value == TransactionStatus.reconciled) {
          // do nothing, its not allowed to change a reconciled transaction
          SnackBarService.displayWarning(
            message: 'Reconcile Transaction Status are prevented from changed.',
          );
          return;
        }
        if (this.fieldStatus.value == TransactionStatus.cleared) {
          // Attempt to restore/undo
          if (valueBeforeEdit != null) {
            // bring back the previous value
            final int oldValue = (valueBeforeEdit![this.fieldStatus.name] ?? 0) as int;
            this.fieldStatus.value = TransactionStatus.values[oldValue];

            // if this was the only change to this instance we can undo the mutation state
            if (mutation == MutationType.changed && MoneyObject.isDataModified(this) == false) {
              mutation = MutationType.none;
              DataController.to.trackMutations.increaseNumber(
                increaseChanged: -1,
              );
            } else {
              DataController.to.trackMutations.setLastEditToNow(); // still need to refresh the UI
            }
          }
        } else {
          mutateField(this.fieldStatus.name, TransactionStatus.cleared, false);
        }
        SelectionController.to.select(this.uniqueId);
      },
    );
  }
}
