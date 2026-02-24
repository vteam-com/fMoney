import 'package:money/data/models/mergeable_item.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/investment_types.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/transaction_types.dart';
import 'package:money/providers/account.dart';
import 'package:money/providers/category.dart';
import 'package:money/providers/data_abstract.dart';
import 'package:money/providers/field_definition_cache.dart';
import 'package:money/providers/investment.dart';
import 'package:money/providers/transaction_split.dart';
import 'package:money/providers/transfer.dart';
import 'package:money/widgets/adaptive_list/list_item_card.dart';
import 'package:money/widgets/data_access.dart';
import 'package:money/widgets/picker_category.dart';
import 'package:money/widgets/picker_edit_box_date.dart';
import 'package:money/widgets/picker_panel.dart';
import 'package:money/widgets/picker_payee_or_transfer.dart';
import 'package:money/widgets/pure/icon_button.dart';
import 'package:money/widgets/pure/mutation_types.dart';
import 'package:money/widgets/pure/snack_bar.dart';
import 'package:money/widgets/selection_controller.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';
import 'package:money/widgets/widgets_domain/field_type.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const int _unsetId = -1;
const int _zeroInt = 0;
const int _oneInt = 1;
const double _zeroDouble = 0.0;
const double _transferPickerWidth = 300.0;
const double _transferPickerHeight = 80.0;

/// Main source of information for this App
/// All transactions are loaded in this class [Transaction] and [Split]
class Transaction extends DataObject implements MergeableItem {
  Transaction({
    final TransactionStatus status = TransactionStatus.none,
    final int accountId = _unsetId,
    required final DateTime? date,
  }) {
    // assert(date != null);
    this.fieldAccountId.value = accountId;
    this.fieldDateTime.value = date;
    this.fieldStatus.value = status;
    this.fieldFlags.value = TransactionFlags.none.index;
  }

  factory Transaction.fromDateDescriptionAmount(
    final dynamic account,
    final DateTime date,
    final String description,
    final double amount,
  ) {
    final dynamic payee = DataAbstract.instance.findOrCreateNewPayee(
      description,
      fireNotification: false,
    );

    final Transaction t = Transaction(date: date);
    t.fieldId.value = _unsetId;
    t.fieldAccountId.value = account is int ? account : ((account as dynamic).uniqueId as num).toInt();
    t.fieldPayee.value = payee == null ? _unsetId : ((payee as dynamic).uniqueId as num).toInt();
    t.fieldMemo.value = description;
    t.fieldAmount.value.setAmount(amount);
    return t;
  }

  factory Transaction.fromJSon(final MyJson json, final double runningBalance) {
    final Transaction t = Transaction(date: json.getDate('Date'));
    // 0 ID
    t.fieldId.value = json.getInt('Id', _unsetId);
    // 1 Account ID
    t.fieldAccountId.value = json.getInt('Account', _unsetId);
    t.instanceOfAccount = DataAbstract.instance.getAccount(t.fieldAccountId.value) as Account?;
    // 3 Status
    t.fieldStatus.value = TransactionStatus.values[json.getInt('Status')];
    // 4 Payee ID
    t.fieldPayee.value = json.getInt('Payee', _unsetId);
    // 5 Original Payee
    t.fieldOriginalPayee.value = json.getString('OriginalPayee');
    // 6 Category Id
    t.fieldCategoryId.value = json.getInt('Category', _unsetId);
    // 7 Memo
    t.fieldMemo.value = json.getString('Memo');
    // 8 Number
    t.fieldNumber.value = json.getString('Number');
    // 9 Reconciled Date
    t.fieldReconciledDate.value = json.getDate('ReconciledDate');
    // 10 BudgetBalanceDate
    t.fieldBudgetBalanceDate.value = json.getDate('BudgetBalanceDate');
    // 11 Transfer
    t.fieldTransfer.value = json.getInt('Transfer', _unsetId);
    // 12 FITID
    t.fieldFitid.value = json.getString('FITID');
    // 13 Flags
    t.fieldFlags.value = json.getInt('Flags');

    // 14 Amount
    t.fieldAmount.value.setAmount(json.getDouble('Amount'));
    // 15 Sales Tax
    t.fieldSalesTax.value.setAmount(json.getDouble('SalesTax'));
    // 16 Transfer Split
    t.fieldTransferSplit.value = json.getInt('TransferSplit', _unsetId);
    // 17 Merge Date
    t.fieldMergeDate.value = json.getDate('MergeDate');

    // not serialized
    t.balance = runningBalance;

    return t;
  }
  @override
  int get categoryId => fieldCategoryId.value;

  @override
  set categoryId(int value) => fieldCategoryId.value = value;

  @override
  int get payeeId => fieldPayee.value;

  @override
  set payeeId(int value) => fieldPayee.value = value;

  /// Balance native
  double balance = _zeroDouble;

  /// Account Id
  /// SQLite  1|Account|INT|1||0
  FieldInt fieldAccountId = FieldInt(
    type: FieldType.text,
    name: 'Account',
    serializeName: 'Account',
    align: TextAlign.left,
    footer: FooterType.count,
    defaultValue: _unsetId,
    getValueForDisplay: (final DataInterface instance) => DataAbstract.instance.getAccountName(
      (instance as Transaction).fieldAccountId.value,
    ),
    getValueForSerialization: (final DataInterface instance) => (instance as Transaction).fieldAccountId.value,
    // setValue: (MoneyObject instance, dynamic newValue) => (instance as Transaction).fieldAccountId.value = newValue,
  );

  /// Amount
  /// 14|Amount|money|1||0
  FieldMoney fieldAmount = FieldMoney(
    name: columnIdAmount,
    serializeName: 'Amount',
    getValueForDisplay: (final DataInterface instance) => AmountModel(
      amount: (instance as Transaction).fieldAmount.value.asDouble(),
      iso4217: instance.currency,
    ),
    getValueForSerialization: (final DataInterface instance) => (instance as Transaction).fieldAmount.value.asDouble(),
    setValue: (final DataInterface instance, dynamic newValue) =>
        (instance as Transaction).fieldAmount.value.setAmount(newValue),
    sort: (final DataInterface a, final DataInterface b, final bool ascending) => sortByValue(
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
    getValueForDisplay: (final DataInterface instance) => AmountModel(
      amount: (instance as Transaction).getNormalizedAmount(
        instance.fieldAmount.value.asDouble(),
      ),
      iso4217: Constants.defaultCurrency,
    ),
    sort: (final DataInterface a, final DataInterface b, final bool ascending) => sortByValue(
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
    getValueForDisplay: (final DataInterface instance) => AmountModel(
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
    getValueForDisplay: (final DataInterface instance) => AmountModel(
      amount: (instance as Transaction).getNormalizedAmount(
        instance.balance,
      ),
      iso4217: Constants.defaultCurrency,
    ),
    sort: (final DataInterface a, final DataInterface b, final bool ascending) => sortByValue(
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
    getValueForDisplay: (final DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as Transaction).fieldBudgetBalanceDate.value,
    ),
    getValueForSerialization: (final DataInterface instance) => dateToIso8601OrDefaultString(
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
    defaultValue: _unsetId,
    getValueForDisplay: (final DataInterface instance) {
      final Transaction t = instance as Transaction;

      final int effectiveCategoryId = t.possibleMatchingCategoryId == _unsetId
          ? t.fieldCategoryId.value
          : t.possibleMatchingCategoryId;
      final String categoryName = DataAbstract.instance.getCategoryNameFromId(
        effectiveCategoryId,
      );
      final Widget categoryWidget = DataAbstract.instance.getCategoryWidget(
        effectiveCategoryId,
      );

      return DataAbstract.instance.categorySuggestionProvider.buildSuggestionWidget(
        onApproved: t.possibleMatchingCategoryId == _unsetId
            ? null
            : () {
                // record the change
                changeCategory(t, t.possibleMatchingCategoryId);
              },
        onChooseCategory: t.fieldCategoryId.value == _unsetId
            ? (final BuildContext context) {
                t.possibleMatchingCategoryId = _unsetId;
                showPopupSelection(
                  title: 'Category',
                  context: context,
                  items: DataAbstract.instance.getCategoriesAsStrings(),
                  selectedItem: '',
                  onSelected: (final String text) {
                    DataAbstract.instance.changeCategoryFromCategoryName(t, text);
                  },
                );
              }
            : null,
        isSplit: t.isSplit,
        transactionString: t.toString(),
        splits: t.splits,
        uniqueId: t.uniqueId,
        totalAmount: t.fieldAmount.value.asDouble(),
        child: Tooltip(message: categoryName, child: categoryWidget),
      );
    },
    getValueForReading: (final DataInterface instance) => (instance as Transaction).categoryName,
    getValueForSerialization: (final DataInterface instance) => (instance as Transaction).fieldCategoryId.value,
    sort: (final DataInterface a, final DataInterface b, final bool ascending) => sortByString(
      (a as Transaction).categoryName,
      (b as Transaction).categoryName,
      ascending,
    ),
    setValue: (final DataInterface instance, dynamic newValue) =>
        (instance as Transaction).fieldCategoryId.value = newValue as int,
    getEditWidget:
        (
          final DataInterface instance,
          void Function(bool /* wasModified */) onEdited,
        ) {
          (instance as Transaction);
          return Row(
            children: <Widget>[
              Expanded(
                child: pickerCategory(
                  key: const Key('key_pick_category'),
                  categoryNames: DataAbstract.instance.getCategoriesAsStrings(),
                  selectedName: DataAbstract.instance.getCategoryNameFromId(instance.fieldCategoryId.value),
                  onSelected: (String? name) {
                    if (name != null) {
                      DataAbstract.instance.changeCategoryFromCategoryName(instance, name);
                      onEdited(true);
                    }
                  },
                ),
              ),
              if (instance.fieldCategoryId.value == DataAbstract.instance.getSplitCategoryId())
                MyIconButton(
                  icon: Icons.arrow_forward_ios,
                  onPressed: () {
                    // Split editing is now handled by SuggestionApproval widget
                    // when the category widget is tapped for split transactions
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
    getValueForReading: (final DataInterface instance) => (instance as Transaction).currency,
    getValueForDisplay: (final DataInterface instance) {
      return buildCurrencyWidget((instance as Transaction).currency);
    },
  );

  /// Date
  /// SQLite 2|Date|datetime|1||0
  FieldDate fieldDateTime = FieldDate(
    name: 'Date',
    serializeName: 'Date',
    getValueForDisplay: (final DataInterface instance) => (instance as Transaction).fieldDateTime.value,
    getValueForSerialization: (final DataInterface instance) =>
        dateToSqliteFormat((instance as Transaction).fieldDateTime.value),
    getEditWidget:
        (
          final DataInterface instance,
          void Function(bool /* wasModified */) onEdited,
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
    setValue: (DataInterface instance, dynamic newValue) =>
        (instance as Transaction).fieldDateTime.value = attemptToGetDateFromText(newValue as String),
    sort: (final DataInterface a, final DataInterface b, final bool ascending) =>
        sortByDateTime(a as Transaction, b as Transaction, ascending),
  );

  /// FITID
  /// 12|FITID|nchar(40)|0||0
  FieldString fieldFitid = FieldString(
    name: 'FITID',
    serializeName: 'FITID',
    getValueForDisplay: (final DataInterface instance) => (instance as Transaction).fieldFitid.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Transaction).fieldFitid.value,
  );

  /// Flags
  /// 13|Flags|INT|1||0
  FieldInt fieldFlags = FieldInt(
    name: 'Flags',
    serializeName: 'Flags',
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForDisplay: (final DataInterface instance) => (instance as Transaction).fieldFlags.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Transaction).fieldFlags.value,
  );

  /// ID
  /// SQLite  0|Id|bigint|0||1
  FieldId fieldId = FieldId(
    getValueForSerialization: (final DataInterface instance) => (instance as Transaction).uniqueId,
  );

  /// Memo
  /// 7|Memo|nvarchar(255)|0||0
  FieldString fieldMemo = FieldString(
    name: 'Memo',
    serializeName: 'Memo',
    getValueForDisplay: (final DataInterface instance) => (instance as Transaction).fieldMemo.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Transaction).fieldMemo.value,
    setValue: (DataInterface instance, dynamic newValue) =>
        (instance as Transaction).fieldMemo.value = newValue as String,
  );

  /// MergeDate
  /// 17|MergeDate|datetime|0||0
  FieldDate fieldMergeDate = FieldDate(
    name: 'Merge Date',
    serializeName: 'MergeDate',
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForSerialization: (final DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as Transaction).fieldMergeDate.value,
    ),
  );

  /// Number
  /// 8|Number|nchar(10)|0||0
  FieldString fieldNumber = FieldString(
    name: 'Ref',
    serializeName: 'Number',
    columnWidth: ColumnWidth.nano,
    getValueForDisplay: (final DataInterface instance) => (instance as Transaction).fieldNumber.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Transaction).fieldNumber.value,
  );

  /// OriginalPayee
  /// before auto-aliasing, helps with future merging.
  /// SQLite 5|OriginalPayee|nvarchar(255)|0||0
  FieldString fieldOriginalPayee = FieldString(
    name: 'Original Payee',
    serializeName: 'OriginalPayee',
    getValueForDisplay: (final DataInterface instance) => (instance as Transaction).fieldOriginalPayee.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Transaction).fieldOriginalPayee.value,
  );

  FieldString fieldPaidOn = FieldString(
    type: FieldType.text,
    name: columnIdPaidOn,
    align: TextAlign.right,
    columnWidth: ColumnWidth.tiny,
    footer: FooterType.none,
    getValueForDisplay: (final DataInterface instance) {
      return (instance as Transaction).fieldPaidOn.value;
    },
  );

  /// Payee Id (displayed as Text name of the Payee)
  /// SQLite 4|Payee|INT|0||0
  FieldInt fieldPayee = FieldInt(
    name: 'Payee/Transfer',
    serializeName: 'Payee',
    defaultValue: _unsetId,
    type: FieldType.text,
    footer: FooterType.count,
    align: TextAlign.left,
    columnWidth: ColumnWidth.largest,
    sort: (final DataInterface a, final DataInterface b, final bool ascending) => sortByString(
      (a as Transaction).payeeName,
      (b as Transaction).payeeName,
      ascending,
    ),
    getValueForDisplay: (final DataInterface instance) {
      return (instance as Transaction).getPayeeOrTransferCaption();
    },
    getValueForSerialization: (final DataInterface instance) => (instance as Transaction).fieldPayee.value,
    setValue: (DataInterface instance, dynamic newValue) {
      instance = instance as Transaction;
      instance.stashOriginalPayee();
      if (newValue == _unsetId || newValue == DataAbstract.instance.getTransferCategoryId()) {
        // -1 means no payee, this is a Transfer?
        // TODO - implement was solution given that the call back here only has one value use for the Payee ID
      } else {
        // Payee
        instance.fieldPayee.value = newValue as int; // Payee Id
        instance.fieldTransfer.value = _unsetId;
        instance.instanceOfTransfer = null;
      }
    },
    getEditWidget:
        (
          DataInterface instance,
          void Function(bool /* wasModified */) onEdited,
        ) {
          return SizedBox(
            width: _transferPickerWidth,
            height: _transferPickerHeight,
            child: PickPayeeOrTransfer(
              choice: (instance as Transaction).fieldTransfer.value == _unsetId
                  ? TransactionFlavor.payee
                  : TransactionFlavor.transfer,
              selectedPayeeName: DataAbstract.instance.getPayeeName(instance.fieldPayee.value),
              selectedAccountName: instance.instanceOfTransfer?.receiverAccount?.fieldName.value,
              amount: instance.fieldAmount.value.asDouble(),
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
                            instance.fieldPayee.value = (selectedPayee as dynamic).uniqueId as int;
                            instance.fieldTransfer.value = _unsetId;
                            instance.instanceOfTransfer = null;
                            wasModified = true;
                          }
                        }
                      case TransactionFlavor.transfer:
                        // this is used to let the dialog Apply code what account should be
                        // used when for transfer with.
                        final dynamic transferAccount = selectedAccountName != null
                            ? DataAbstract.instance.getAccountByName(selectedAccountName)
                            : null;
                        instance.editingTransferAccount = transferAccount as Account?;
                        instance.fieldTransfer.value = _unsetId; // this will cause a reevaluation of the transfer

                        if (transferAccount == null) {
                          // No account has been selected yet by the users
                          // do nothing since this is just the user taping between Payee | Transfer
                          instance.fieldPayee.value = _unsetId;
                        } else {
                          // mark as Transfer
                          instance.fieldPayee.value = DataAbstract.instance.getTransferCategoryId();
                        }
                        wasModified = true;
                    }
                    onEdited(wasModified); // notify container
                  },
              onMergePayee: (String payeeName, BuildContext context) {
                final dynamic payee = DataAbstract.instance.getPayeeByName(payeeName);
                if (payee != null) {
                  final Iterable<dynamic> transactions = DataAbstract.instance
                      .getTransactions(
                        includeDeleted: true,
                      )
                      .where((dynamic t) => (t as Transaction).fieldPayee.value == (payee as dynamic).uniqueId);
                  Navigator.of(context).pop(false);
                  DataAbstract.instance.mergePayeeProvider.showMergePayee(
                    context,
                    payee,
                    transactions,
                    DataAbstract.instance,
                  );
                }
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
    getValueForDisplay: (final DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as Transaction).fieldReconciledDate.value,
    ),
    getValueForSerialization: (final DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as Transaction).fieldReconciledDate.value,
    ),
  );

  /// Sales Tax
  /// 15|SalesTax|money|0||0
  FieldMoney fieldSalesTax = FieldMoney(
    name: 'Sales Tax',
    serializeName: 'SalesTax',
    getValueForDisplay: (final DataInterface instance) => (instance as Transaction).fieldSalesTax.value,
    getValueForSerialization: (final DataInterface instance) =>
        (instance as Transaction).fieldSalesTax.value.asDouble(),
    sort: (final DataInterface a, final DataInterface b, final bool ascending) => sortByValue(
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
    getValueForDisplay: (final DataInterface instance) => (instance as Transaction)._buildStatusButtonToggle(),
    getValueForSerialization: (final DataInterface instance) => (instance as Transaction).fieldStatus.value.index,
    setValue: (DataInterface instance, dynamic newValue) =>
        (instance as Transaction).fieldStatus.value = newValue as TransactionStatus,
    sort: (final DataInterface a, final DataInterface b, final bool ascending) => sortByString(
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
    defaultValue: _unsetId,
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForDisplay: (final DataInterface instance) => (instance as Transaction).fieldTransfer.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Transaction).fieldTransfer.value,
  );

  /// Transfer Split
  /// 16|TransferSplit|INT|0||0
  FieldInt fieldTransferSplit = FieldInt(
    name: 'TransferSplit',
    serializeName: 'TransferSplit',
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForDisplay: (final DataInterface instance) => (instance as Transaction).fieldTransferSplit.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Transaction).fieldTransferSplit.value,
  );

  /// cache instances of related MoneyObjects
  Investment? instanceOfInvestment;

  int possibleMatchingCategoryId = _unsetId;
  List<TransactionSplit> splits = <TransactionSplit>[];

  /// Instances of related MoneyObjects
  dynamic _instanceOfAccount;

  // Instance of Transfer
  Transfer? _instanceOfTransfer;

  @override
  Widget buildFieldsAsWidgetForSmallScreen() {
    return MyListItemAsCard(
      leftTopAsString: payeeName,
      leftBottomAsString: '${DataAbstract.instance.getCategoryNameFromId(fieldCategoryId.value)}\n${fieldMemo.value}',
      rightTopAsWidget: WidgetFromData(
        amountModel: fieldAmount.value,
        size: DataWidgetSize.title,
      ),
      rightBottomAsString: '$dateTimeAsString\n${DataAbstract.instance.getAccountName(fieldAccountId.value)}',
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
  DataObject rollup(List<DataObject> moneyObjectInstances) {
    if (moneyObjectInstances.isEmpty) {
      return Transaction(date: DateTime.now());
    }
    if (moneyObjectInstances.length == _oneInt) {
      return moneyObjectInstances.first;
    }

    MyJson commonJson = moneyObjectInstances.first.getPersistableJSon();

    for (DataObject t in moneyObjectInstances.skip(_oneInt)) {
      commonJson = compareAndGenerateCommonJson(
        commonJson,
        t.getPersistableJSon(),
      );
    }
    return Transaction.fromJSon(commonJson, _zeroDouble);
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
  static final Fields<Transaction> _fieldsForColumns = Fields<Transaction>();
  static final List<FieldBlueprint<Transaction>> _fieldBlueprints = <FieldBlueprint<Transaction>>[
    FieldBlueprint<Transaction>(selector: (Transaction tmp) => tmp.fieldId),
    FieldBlueprint<Transaction>(
      selector: (Transaction tmp) => tmp.fieldDateTime,
      includeInColumnView: true,
    ),
    FieldBlueprint<Transaction>(
      selector: (Transaction tmp) => tmp.fieldAccountId,
      includeInColumnView: true,
    ),
    FieldBlueprint<Transaction>(
      selector: (Transaction tmp) => tmp.fieldNumber,
      includeInEntity: false,
      includeInColumnView: true,
    ),
    FieldBlueprint<Transaction>(
      selector: (Transaction tmp) => tmp.fieldPayee,
      includeInColumnView: true,
    ),
    FieldBlueprint<Transaction>(selector: (Transaction tmp) => tmp.fieldOriginalPayee),
    FieldBlueprint<Transaction>(
      selector: (Transaction tmp) => tmp.fieldCategoryId,
      includeInColumnView: true,
    ),
    FieldBlueprint<Transaction>(selector: (Transaction tmp) => tmp.fieldMemo, includeInColumnView: true),
    FieldBlueprint<Transaction>(selector: (Transaction tmp) => tmp.fieldNumber),
    FieldBlueprint<Transaction>(selector: (Transaction tmp) => tmp.fieldReconciledDate),
    FieldBlueprint<Transaction>(selector: (Transaction tmp) => tmp.fieldBudgetBalanceDate),
    FieldBlueprint<Transaction>(selector: (Transaction tmp) => tmp.fieldTransfer),
    FieldBlueprint<Transaction>(selector: (Transaction tmp) => tmp.fieldStatus, includeInColumnView: true),
    FieldBlueprint<Transaction>(selector: (Transaction tmp) => tmp.fieldFitid),
    FieldBlueprint<Transaction>(selector: (Transaction tmp) => tmp.fieldFlags),
    FieldBlueprint<Transaction>(selector: (Transaction tmp) => tmp.fieldCurrency, includeInColumnView: true),
    FieldBlueprint<Transaction>(selector: (Transaction tmp) => tmp.fieldSalesTax),
    FieldBlueprint<Transaction>(selector: (Transaction tmp) => tmp.fieldTransferSplit),
    FieldBlueprint<Transaction>(selector: (Transaction tmp) => tmp.fieldMergeDate),
    FieldBlueprint<Transaction>(selector: (Transaction tmp) => tmp.fieldAmount, includeInColumnView: true),
    FieldBlueprint<Transaction>(
      selector: (Transaction tmp) => tmp.fieldAmountAsTextNormalized,
      includeInColumnView: true,
    ),
    FieldBlueprint<Transaction>(selector: (Transaction tmp) => tmp.fieldBalanceNative),
    FieldBlueprint<Transaction>(
      selector: (Transaction tmp) => tmp.fieldBalanceNormalized,
      includeInColumnView: true,
    ),
    FieldBlueprint<Transaction>(selector: (Transaction tmp) => tmp.fieldPaidOn),
  ];

  /// Returns the account name for this transaction.
  String get accountName => instanceOfAccount?.fieldName.value ?? '<Account???>';

  /// Returns the transaction amount formatted as a string.
  String get amountAsString => fieldAmount.value.toString();

  /// Returns the category instance for this transaction.
  Category? get category => DataAbstract.instance.getCategory(this.fieldCategoryId.value) as Category?;

  /// Returns the category name for this transaction.
  String get categoryName => DataAbstract.instance.getCategoryNameFromId(this.fieldCategoryId.value);

  /// Changes the category for the given transaction and notifies listeners.
  static void changeCategory(dynamic t, final int categoryId) {
    // record the change
    (t as Transaction).stashValueBeforeEditing();

    // Make change
    t.fieldCategoryId.value = categoryId;
    t.possibleMatchingCategoryId = _unsetId;

    // inform of changes
    DataAbstract.instance.notifyMutationChanged(
      mutation: MutationType.changed,
      moneyObject: t,
      recalculateBalances: true,
    );
  }

  /// TODO - clean this up,
  void checkTransfers(
    Set<Transaction> dangling,
    List<dynamic> deletedAccounts,
  ) {
    keepUnused(deletedAccounts);
    if (fieldTransfer.value != _unsetId && this.instanceOfTransfer == null) {
      // transferInstance?.getReceiverAccount();
      // if (IsDeletedAccount(this.to, money, deletedAccounts)) {
      //   this.Category =
      //       this.Amount < 0 ? DataAbstract.instance.categories.TransferToDeletedAccount : money.Categories.TransferFromDeletedAccount;
      //   this.to = null;
      // } else {
      dangling.add(this);
      // }
    }

    if (this.instanceOfTransfer != null) {
      final Transaction other = this.instanceOfTransfer!.relatedTransaction as Transaction;
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
        if (other.instanceOfTransfer == null ||
            (other.instanceOfTransfer?.relatedTransaction as Transaction?) != this) {
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

  /// Returns true if this transaction transfers to the given account.
  bool containsTransferTo(dynamic a) {
    if (this.isSplit) {
      for (TransactionSplit s in this.splits) {
        if (s.fieldTransferId.value != _unsetId && s.getTransferTransaction()?.fieldAccountId.value == a.uniqueId) {
          return true;
        }
      }
    }
    if (this.instanceOfTransfer != null &&
        (this.instanceOfTransfer?.relatedTransaction as dynamic)?.fieldAccountId.value == (a as dynamic).uniqueId) {
      return true;
    }
    return false;
  }

  /// Returns the currency code for this transaction.
  String get currency {
    if (this.instanceOfAccount == null || (this.instanceOfAccount as dynamic).fieldCurrency.value.isEmpty == true) {
      return Constants.defaultCurrency;
    }

    return (this.instanceOfAccount as dynamic).fieldCurrency.value.toString();
  }

  /// Returns the transaction date as a YYYY-MM-DD string.
  String get dateTimeAsString => dateToString(fieldDateTime.value);

  /// Returns the field definitions for Transaction entities.
  static Fields<Transaction> get fields => ensureCachedFieldDefinitionsFromBlueprints<Transaction>(
    cache: _fields,
    instanceFactory: () => Transaction(date: DateTime.now()),
    blueprints: _fieldBlueprints,
    forColumnView: false,
  );

  /// Returns the field definitions for Transaction column view.
  static Fields<Transaction> get fieldsForColumnView => ensureCachedFieldDefinitionsFromBlueprints<Transaction>(
    cache: _fieldsForColumns,
    instanceFactory: () => Transaction(date: DateTime.now()),
    blueprints: _fieldBlueprints,
    forColumnView: true,
  );

  /// Converts a native amount to normalized currency using the account ratio.
  double getNormalizedAmount(double nativeValue) {
    // Convert the value to USD
    if (instanceOfAccount == null || (instanceOfAccount as dynamic).getCurrencyRatio() as num == _zeroDouble) {
      return nativeValue;
    }
    return nativeValue * instanceOfAccount!.getCurrencyRatio();
  }

  /// Returns the investment associated with this transaction, creating one if needed.
  Investment getOrCreateInvestment() {
    instanceOfInvestment ??=
        DataAbstract.instance.getInvestment(this.uniqueId) as Investment? ??
        Investment(
          id: this.uniqueId,
          security: _unsetId,
          unitPrice: _zeroDouble,
          units: _zeroDouble,
          investmentType: _zeroInt,
          tradeType: _zeroInt,
        );
    return instanceOfInvestment!;
  }

  /// Returns a caption using either payee information or transfer information.
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
      } else if (amount > _zeroDouble) {
        isFrom = true;
      }

      return getTransferCaption(
        instanceOfTransfer?.receiverAccount,
        isFrom,
        showAccount: showAccount,
      );
    } else {
      displayName = DataAbstract.instance.getPayeeName(fieldPayee.value);
    }
    return displayName.isEmpty ? '<Payee???>' : displayName;
  }

  /// Builds a display caption for a transfer.
  String getTransferCaption(
    final dynamic relatedAccount,
    final bool isFrom, {
    final bool showAccount = false,
  }) {
    String caption = showAccount ? accountName : 'Transfer';
    final String arrowDirection = isFrom ? ' ← ' : ' → ';
    caption += arrowDirection;
    caption += relatedAccountName(relatedAccount);
    return caption;
  }

  /// Returns the account instance for this transaction.
  Account? get instanceOfAccount {
    /// cache instances of related MoneyObjects
    _instanceOfAccount ??= DataAbstract.instance.getAccount(this.fieldAccountId.value) as Account?;
    return _instanceOfAccount as Account?;
  }

  /// Sets the cached account instance for this transaction.
  set instanceOfAccount(Account? value) {
    _instanceOfAccount = value;
  }

  /// Returns the transfer instance for this transaction, creating linkage if needed.
  Transfer? get instanceOfTransfer {
    if (_instanceOfTransfer == null && isTransfer) {
      final Transaction? relatedTransaction =
          DataAbstract.instance.getTransaction(
                this.fieldTransfer.value,
              )
              as Transaction?;
      if (relatedTransaction != null) {
        linkTransfer(this, relatedTransaction);
      }
    }
    return _instanceOfTransfer;
  }

  /// Sets the cached transfer instance for this transaction.
  set instanceOfTransfer(Transfer? value) {
    _instanceOfTransfer = value;
  }

  /// True if this transaction belongs to an asset account.
  bool get isAssetAccount => DataAbstract.instance.isAccountAsset(fieldAccountId.value);

  /// True if this transaction is eligible to be included in budgets.
  bool get isCandidateForBudget => this.fieldCategoryId.value != _unsetId && (this.isExpense || this.isIncome);

  /// True if this transaction is categorized as an expense.
  bool get isExpense => DataAbstract.instance.isCategoryExpense(fieldCategoryId.value);

  /// True if this transaction is categorized as an income.
  bool get isIncome => DataAbstract.instance.isCategoryIncome(fieldCategoryId.value);

  /// Returns true if this transaction or any split matches a category in [categoriesToMatch].
  bool isMatchingAnyOfTheseCategories(List<int> categoriesToMatch) {
    if (categoriesToMatch.contains(fieldCategoryId.value)) {
      return true;
    }

    if (this.isSplit) {
      for (final TransactionSplit s in this.splits) {
        if (categoriesToMatch.contains(s.fieldCategoryId.value)) {
          return true;
        }
      }
    }
    return false;
  }

  /// True if this transaction contains splits.
  bool get isSplit => this.splits.isNotEmpty;

  /// True if this transaction is linked to another transaction as a transfer.
  bool get isTransfer => fieldTransfer.value != _unsetId;

  /// Returns a one-line description combining payee/transfer caption and category.
  String get oneLinePayeeAndDescription {
    String description = this.getPayeeOrTransferCaption(showAccount: true);

    if (this.categoryName.isNotEmpty) {
      description += ' | ${this.categoryName}';
    }

    return description;
  }

  /// Returns the payee name for this transaction.
  String get payeeName => DataAbstract.instance.getPayeeName(fieldPayee.value);

  /// Find all the objects referenced by this Transaction and wire them back up

  /// <param name="money">The owner</param>
  /// <param name="parent">The container</param>
  /// <param name="from">The account this transaction belongs to</param>
  /// <param name="duplicateTransfers">How to handle transfers.  In a cut/paste situation you want
  /// to create new transfer transactions (true), but in a XmlStore.Load situation we do not (false)</param>
  // void postDeserializeFixup(bool duplicateTransfers) {
  //   keepUnused(duplicateTransfers);
  // TODO: implement postDeserializeFixup
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
  // if (this.categoryId == DataAbstract.instance.categories.splitCategoryId()) {
  //   DataAbstract.instance.this.Splits.Transaction = this;
  //   this.Splits.Parent = this;
  //   foreach (Split s in this.Splits.Items)
  //   {
  //     s.PostDeserializeFixup(money, this, duplicateTransfers);
  //   }
  // }
  // }

  /// Returns the account on the other side of a transfer, if any.
  dynamic get relatedAccount => (instanceOfTransfer?.relatedTransaction as dynamic)?.instanceOfAccount;

  /// Returns a display name for a related account, including closed-account marker.
  String relatedAccountName(dynamic relatedAccount) {
    if (relatedAccount == null) {
      return '<Account???>';
    }
    String name = '';

    if ((relatedAccount as Account).isClosed()) {
      name += 'Closed-Account: ';
    }
    return name + relatedAccount.fieldName.value;
  }

  /// Sorts transactions by date/time with ID as a tiebreaker.
  static int sortByDateTime(
    final dynamic a,
    final dynamic b,
    final bool ascending,
  ) {
    int result = sortByDate(
      (a as Transaction).fieldDateTime.value,
      (b as Transaction).fieldDateTime.value!,
      ascending,
    );
    // To ensure a predictable sort order, always include a tie-breaker
    if (result == _zeroInt) {
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

  /// Builds a toggle button for transaction status.
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
            final int oldValue = (valueBeforeEdit![this.fieldStatus.name] ?? _zeroInt) as int;
            this.fieldStatus.value = TransactionStatus.values[oldValue];

            // if this was the only change to this instance we can undo the mutation state
            if (mutation == MutationType.changed && DataObject.isDataModified(this) == false) {
              mutation = MutationType.none;
              DataAccess.trackMutations.increaseNumber(
                increaseChanged: _unsetId,
              );
            } else {
              DataAccess.trackMutations.setLastEditToNow(); // still need to refresh the UI
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

/// Links two transactions as a transfer pair
void linkTransfer(
  dynamic transactionSource,
  dynamic transactionRelated,
) {
  (transactionSource as Transaction).instanceOfTransfer = Transfer(
    id: _zeroInt,
    source: transactionSource,
    relatedTransaction: transactionRelated,
    isOrphan: false,
  );

  (transactionRelated as Transaction).instanceOfTransfer = Transfer(
    id: _zeroInt,
    source: transactionRelated,
    relatedTransaction: transactionSource,
    isOrphan: false,
  );
}
