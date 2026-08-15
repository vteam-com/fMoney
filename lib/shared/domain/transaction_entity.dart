import 'package:money/data/helpers/transaction_type_helper.dart';
import 'package:money/data/models/field_type_enum.dart';
import 'package:money/data/models/mergeable_item_interface.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/field_definition_cache_helper.dart';
import 'package:money/shared/domain/investment_entity.dart';
import 'package:money/shared/domain/transaction_delegate_utils.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/shared/domain/transfer_entity.dart';
import 'package:money/widgets/list/list_item_card.dart';
import 'package:money/widgets/pickers/category_picker_widget.dart';
import 'package:money/widgets/pickers/edit_box_date_picker_widget.dart';
import 'package:money/widgets/pickers/payee_or_transfer_picker_widget.dart';
import 'package:money/widgets/pickers/picker_panel.dart';
import 'package:money/widgets/pure/icon_button.dart';
import 'package:money/widgets/pure/mutation_types.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';
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
    TransactionStatus status = TransactionStatus.none,
    int accountId = _unsetId,
    required DateTime? date,
  }) {
    // assert(date != null);
    this.fieldAccountId.value = accountId;
    this.fieldDateTime.value = date;
    this.fieldStatus.value = status;
    this.fieldFlags.value = TransactionFlags.none.index;
  }

  factory Transaction.fromDateDescriptionAmount(
    dynamic account,
    DateTime date,
    String description,
    double amount,
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

  factory Transaction.fromJSon(MyJson json, double runningBalance) {
    final Transaction t = Transaction(date: json.getDate(SharedDomainStrings.domainString044));
    // 0 ID
    t.fieldId.value = json.getInt(SharedDomainStrings.domainString057, _unsetId);
    // 1 Account ID
    t.fieldAccountId.value = json.getInt(SharedDomainStrings.domainString011, _unsetId);
    t.instanceOfAccount = DataAbstract.instance.getAccount(t.fieldAccountId.value) as Account?;
    // 3 Status
    t.fieldStatus.value = TransactionStatus.values[json.getInt(SharedDomainStrings.domainString128)];
    // 4 Payee ID
    t.fieldPayee.value = json.getInt(SharedDomainStrings.domainString105, _unsetId);
    // 5 Original Payee
    t.fieldOriginalPayee.value = json.getString(SharedDomainStrings.domainString100);
    // 6 Category Id
    t.fieldCategoryId.value = json.getInt(SharedDomainStrings.domainString029, _unsetId);
    // 7 Memo
    t.fieldMemo.value = json.getString(SharedDomainStrings.domainString086);
    // 8 Number
    t.fieldNumber.value = json.getString(SharedDomainStrings.domainString092);
    // 9 Reconciled Date
    t.fieldReconciledDate.value = json.getDate(SharedDomainStrings.domainString116);
    // 10 BudgetBalanceDate
    t.fieldBudgetBalanceDate.value = json.getDate(SharedDomainStrings.domainString025);
    // 11 Transfer
    t.fieldTransfer.value = json.getInt(SharedDomainStrings.domainString144, _unsetId);
    // 12 FITID
    t.fieldFitid.value = json.getString(SharedDomainStrings.domainString051);
    // 13 Flags
    t.fieldFlags.value = json.getInt(SharedDomainStrings.domainString055);

    // 14 Amount
    t.fieldAmount.value.setAmount(json.getDouble(SharedDomainStrings.domainString017));
    // 15 Sales Tax
    t.fieldSalesTax.value.setAmount(json.getDouble(SharedDomainStrings.domainString121));
    // 16 Transfer Split
    t.fieldTransferSplit.value = json.getInt(SharedDomainStrings.domainString145, _unsetId);
    // 17 Merge Date
    t.fieldMergeDate.value = json.getDate(SharedDomainStrings.domainString087);

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

  /// Color used to visually link paired credit-card statement-close and payment rows.
  /// Null means no pairing (no right-edge stripe).
  Color? pairHighlightColor;

  /// True when this row is the first row of a statement gradient region.
  bool pairHighlightTopCap = false;

  /// True when this row is the payment row ending a statement gradient region.
  bool pairHighlightBottomCap = false;

  @override
  Color getRightAdornmentColor() => pairHighlightColor ?? Colors.transparent;

  @override
  bool getShowRightAdornmentTopCap() => pairHighlightTopCap;

  @override
  bool getShowRightAdornmentBottomCap() => pairHighlightBottomCap;

  /// Account Id
  /// SQLite  1|Account|INT|1||0
  FieldInt fieldAccountId = FieldInt(
    type: FieldType.text,
    name: SharedDomainStrings.domainString011,
    serializeName: SharedDomainStrings.domainString011,
    align: TextAlign.left,
    footer: FooterType.count,
    defaultValue: _unsetId,
    getValueForDisplay: (DataInterface instance) => DataAbstract.instance.getAccountName(
      (instance as Transaction).fieldAccountId.value,
    ),
    getValueForSerialization: (DataInterface instance) => (instance as Transaction).fieldAccountId.value,
    // setValue: (MoneyObject instance, dynamic newValue) => (instance as Transaction).fieldAccountId.value = newValue,
  );

  /// Amount
  /// 14|Amount|money|1||0
  FieldMoney fieldAmount = FieldMoney(
    name: columnIdAmount,
    serializeName: SharedDomainStrings.domainString017,
    getValueForDisplay: (DataInterface instance) => AmountModel(
      amount: (instance as Transaction).fieldAmount.value.asDouble(),
      iso4217: instance.currency,
    ),
    getValueForSerialization: (DataInterface instance) => (instance as Transaction).fieldAmount.value.asDouble(),
    setValue: (DataInterface instance, dynamic newValue) =>
        (instance as Transaction).fieldAmount.value.setAmount(newValue),
    sort: (DataInterface a, DataInterface b, bool ascending) => sortByValue(
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
    getValueForDisplay: (DataInterface instance) => AmountModel(
      amount: (instance as Transaction).getNormalizedAmount(
        instance.fieldAmount.value.asDouble(),
      ),
      iso4217: Constants.defaultCurrency,
    ),
    sort: (DataInterface a, DataInterface b, bool ascending) => sortByValue(
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
    getValueForDisplay: (DataInterface instance) => AmountModel(
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
    getValueForDisplay: (DataInterface instance) => AmountModel(
      amount: (instance as Transaction).getNormalizedAmount(
        instance.balance,
      ),
      iso4217: Constants.defaultCurrency,
    ),
    sort: (DataInterface a, DataInterface b, bool ascending) => sortByValue(
      (a as Transaction).balance,
      (b as Transaction).balance,
      ascending,
    ),
  );

  /// Budget Balance Date
  /// 10|BudgetBalanceDate|datetime|0||0
  FieldDate fieldBudgetBalanceDate = FieldDate(
    name: SharedDomainStrings.domainString116,
    serializeName: SharedDomainStrings.domainString116,
    getValueForDisplay: (DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as Transaction).fieldBudgetBalanceDate.value,
    ),
    getValueForSerialization: (DataInterface instance) => dateToIso8601OrDefaultString(
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
    name: SharedDomainStrings.domainString029,
    serializeName: SharedDomainStrings.domainString029,
    defaultValue: _unsetId,
    getValueForDisplay: (DataInterface instance) {
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
            ? (BuildContext context) {
                t.possibleMatchingCategoryId = _unsetId;
                showPopupSelection(
                  title: SharedDomainStrings.domainString029,
                  context: context,
                  items: DataAbstract.instance.getCategoriesAsStrings(),
                  selectedItem: '',
                  onSelected: (String text) {
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
    getValueForReading: (DataInterface instance) => (instance as Transaction).categoryName,
    getValueForSerialization: (DataInterface instance) => (instance as Transaction).fieldCategoryId.value,
    sort: (DataInterface a, DataInterface b, bool ascending) => sortByString(
      (a as Transaction).categoryName,
      (b as Transaction).categoryName,
      ascending,
    ),
    setValue: (DataInterface instance, dynamic newValue) =>
        (instance as Transaction).fieldCategoryId.value = newValue as int,
    getEditWidget:
        (
          DataInterface instance,
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
    name: SharedDomainStrings.domainString042,
    align: TextAlign.center,
    columnWidth: ColumnWidth.tiny,
    footer: FooterType.count,
    getValueForReading: (DataInterface instance) => (instance as Transaction).currency,
    getValueForDisplay: (DataInterface instance) {
      return buildCurrencyWidget((instance as Transaction).currency);
    },
  );

  /// Date
  /// SQLite 2|Date|datetime|1||0
  FieldDate fieldDateTime = FieldDate(
    name: SharedDomainStrings.domainString044,
    serializeName: SharedDomainStrings.domainString044,
    getValueForDisplay: (DataInterface instance) => (instance as Transaction).fieldDateTime.value,
    getValueForSerialization: (DataInterface instance) =>
        dateToSqliteFormat((instance as Transaction).fieldDateTime.value),
    getEditWidget:
        (
          DataInterface instance,
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
    sort: (DataInterface a, DataInterface b, bool ascending) =>
        sortByDateTime(a as Transaction, b as Transaction, ascending),
  );

  /// FITID
  /// 12|FITID|nchar(40)|0||0
  FieldString fieldFitid = FieldString(
    name: SharedDomainStrings.domainString051,
    serializeName: SharedDomainStrings.domainString051,
    getValueForDisplay: (DataInterface instance) => (instance as Transaction).fieldFitid.value,
    getValueForSerialization: (DataInterface instance) => (instance as Transaction).fieldFitid.value,
  );

  /// Flags
  /// 13|Flags|INT|1||0
  FieldInt fieldFlags = FieldInt(
    name: SharedDomainStrings.domainString055,
    serializeName: SharedDomainStrings.domainString055,
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForDisplay: (DataInterface instance) => (instance as Transaction).fieldFlags.value,
    getValueForSerialization: (DataInterface instance) => (instance as Transaction).fieldFlags.value,
  );

  /// ID
  /// SQLite  0|Id|bigint|0||1
  FieldId fieldId = FieldId(
    getValueForSerialization: (DataInterface instance) => (instance as Transaction).uniqueId,
  );

  /// Memo
  /// 7|Memo|nvarchar(255)|0||0
  FieldString fieldMemo = FieldString(
    name: SharedDomainStrings.domainString086,
    serializeName: SharedDomainStrings.domainString086,
    getValueForDisplay: (DataInterface instance) => (instance as Transaction).fieldMemo.value,
    getValueForSerialization: (DataInterface instance) => (instance as Transaction).fieldMemo.value,
    setValue: (DataInterface instance, dynamic newValue) =>
        (instance as Transaction).fieldMemo.value = newValue as String,
  );

  /// MergeDate
  /// 17|MergeDate|datetime|0||0
  FieldDate fieldMergeDate = FieldDate(
    name: 'Merge Date',
    serializeName: SharedDomainStrings.domainString087,
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForSerialization: (DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as Transaction).fieldMergeDate.value,
    ),
  );

  /// Number
  /// 8|Number|nchar(10)|0||0
  FieldString fieldNumber = FieldString(
    name: 'Ref',
    serializeName: SharedDomainStrings.domainString092,
    columnWidth: ColumnWidth.nano,
    getValueForDisplay: (DataInterface instance) => (instance as Transaction).fieldNumber.value,
    getValueForSerialization: (DataInterface instance) => (instance as Transaction).fieldNumber.value,
  );

  /// OriginalPayee
  /// before auto-aliasing, helps with future merging.
  /// SQLite 5|OriginalPayee|nvarchar(255)|0||0
  FieldString fieldOriginalPayee = FieldString(
    name: 'Original Payee',
    serializeName: SharedDomainStrings.domainString100,
    getValueForDisplay: (DataInterface instance) => (instance as Transaction).fieldOriginalPayee.value,
    getValueForSerialization: (DataInterface instance) => (instance as Transaction).fieldOriginalPayee.value,
  );

  FieldString fieldPaidOn = FieldString(
    type: FieldType.text,
    name: columnIdPaidOn,
    align: TextAlign.right,
    columnWidth: ColumnWidth.tiny,
    footer: FooterType.none,
    getValueForDisplay: (DataInterface instance) {
      return (instance as Transaction).fieldPaidOn.value;
    },
  );

  /// Payee Id (displayed as Text name of the Payee)
  /// SQLite 4|Payee|INT|0||0
  FieldInt fieldPayee = FieldInt(
    name: 'Payee/Transfer',
    serializeName: SharedDomainStrings.domainString105,
    defaultValue: _unsetId,
    type: FieldType.widget,
    footer: FooterType.count,
    align: TextAlign.left,
    columnWidth: ColumnWidth.largest,
    sort: (DataInterface a, DataInterface b, bool ascending) => sortByString(
      (a as Transaction).payeeName,
      (b as Transaction).payeeName,
      ascending,
    ),
    getValueForDisplay: (DataInterface instance) {
      return transactionBuildPayeeOrTransferWidget(instance as Transaction);
    },
    getValueForSerialization: (DataInterface instance) => (instance as Transaction).fieldPayee.value,
    setValue: (DataInterface instance, dynamic newValue) {
      final Transaction transaction = instance as Transaction;
      transaction.stashOriginalPayee();
      if (newValue == _unsetId || newValue == DataAbstract.instance.getTransferCategoryId()) {
        // -1 means no payee, this is a Transfer?
        // TODO - implement was solution given that the call back here only has one value use for the Payee ID
      } else {
        // Payee
        transaction.fieldPayee.value = newValue as int; // Payee Id
        transaction.fieldTransfer.value = _unsetId;
        transaction.instanceOfTransfer = null;
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
    name: SharedDomainStrings.domainString116,
    serializeName: SharedDomainStrings.domainString116,
    getValueForDisplay: (DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as Transaction).fieldReconciledDate.value,
    ),
    getValueForSerialization: (DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as Transaction).fieldReconciledDate.value,
    ),
  );

  /// Sales Tax
  /// 15|SalesTax|money|0||0
  FieldMoney fieldSalesTax = FieldMoney(
    name: 'Sales Tax',
    serializeName: SharedDomainStrings.domainString121,
    getValueForDisplay: (DataInterface instance) => (instance as Transaction).fieldSalesTax.value,
    getValueForSerialization: (DataInterface instance) => (instance as Transaction).fieldSalesTax.value.asDouble(),
    sort: (DataInterface a, DataInterface b, bool ascending) => sortByValue(
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
    serializeName: SharedDomainStrings.domainString128,
    getValueForDisplay: (DataInterface instance) => (instance as Transaction)._buildStatusButtonToggle(),
    getValueForSerialization: (DataInterface instance) => (instance as Transaction).fieldStatus.value.index,
    setValue: (DataInterface instance, dynamic newValue) =>
        (instance as Transaction).fieldStatus.value = newValue as TransactionStatus,
    sort: (DataInterface a, DataInterface b, bool ascending) => sortByString(
      transactionStatusToLetter((a as Transaction).fieldStatus.value),
      transactionStatusToLetter((b as Transaction).fieldStatus.value),
      ascending,
    ),
  );

  /// Transfer
  /// 11|Transfer|bigint|0||0
  Field<int> fieldTransfer = Field<int>(
    name: SharedDomainStrings.domainString144,
    serializeName: SharedDomainStrings.domainString144,
    defaultValue: _unsetId,
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForDisplay: (DataInterface instance) => (instance as Transaction).fieldTransfer.value,
    getValueForSerialization: (DataInterface instance) => (instance as Transaction).fieldTransfer.value,
  );

  /// Transfer Split
  /// 16|TransferSplit|INT|0||0
  FieldInt fieldTransferSplit = FieldInt(
    name: SharedDomainStrings.domainString145,
    serializeName: SharedDomainStrings.domainString145,
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForDisplay: (DataInterface instance) => (instance as Transaction).fieldTransferSplit.value,
    getValueForSerialization: (DataInterface instance) => (instance as Transaction).fieldTransferSplit.value,
  );

  /// cache instances of related MoneyObjects
  Investment? instanceOfInvestment;

  int possibleMatchingCategoryId = _unsetId;
  List<TransactionSplit> splits = <TransactionSplit>[];

  /// Instances of related MoneyObjects
  dynamic _instanceOfAccount;

  // Instance of Transfer
  Transfer? cachedTransfer;

  @override
  Widget buildFieldsAsWidgetForSmallScreen() {
    return MyListItemAsCard(
      leftTopAsString: payeeName,
      leftBottomAsString:
          '${DataAbstract.instance.getCategoryNameFromId(fieldCategoryId.value)}${SharedDomainStrings.domainString158}${fieldMemo.value}',
      rightTopAsWidget: WidgetFromData(
        amountModel: fieldAmount.value,
        size: DataWidgetSize.title,
      ),
      rightBottomAsString:
          '$dateTimeAsString${SharedDomainStrings.domainString158}${DataAbstract.instance.getAccountName(fieldAccountId.value)}',
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
  set uniqueId(int value) => fieldId.value = value;

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

  /// Returns the display account name for this transaction.
  String get accountName => instanceOfAccount?.fieldName.value ?? SharedDomainStrings.domainString006;

  /// Returns the transaction amount formatted using account currency rules.
  String get amountAsString => fieldAmount.value.toString();

  /// Returns the resolved category object for this transaction, if any.
  Category? get category => DataAbstract.instance.getCategory(this.fieldCategoryId.value) as Category?;

  /// Returns the resolved category name for this transaction.
  String get categoryName => DataAbstract.instance.getCategoryNameFromId(this.fieldCategoryId.value);

  /// Changes the category for the given transaction and notifies listeners.
  static void changeCategory(dynamic t, int categoryId) {
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

  /// Validates transfer linkage and appends broken links to [dangling].
  void checkTransfers(
    Set<Transaction> dangling,
    List<dynamic> deletedAccounts,
  ) {
    transactionCheckTransfers(this, dangling, deletedAccounts);
  }

  /// Returns true if this transaction or one of its splits transfers to account [a].
  bool containsTransferTo(dynamic a) {
    return transactionContainsTransferTo(this, a);
  }

  /// Returns the transaction currency code derived from the linked account.
  String get currency {
    if (this.instanceOfAccount == null || (this.instanceOfAccount as dynamic).fieldCurrency.value.isEmpty == true) {
      return Constants.defaultCurrency;
    }

    return (this.instanceOfAccount as dynamic).fieldCurrency.value.toString();
  }

  /// Returns the transaction date as a compact display string.
  String get dateTimeAsString => dateToString(fieldDateTime.value);

  /// Returns cached field definitions for entity/detail views.
  static Fields<Transaction> get fields => ensureCachedFieldDefinitionsFromBlueprints<Transaction>(
    cache: _fields,
    instanceFactory: () => Transaction(date: DateTime.now()),
    blueprints: _fieldBlueprints,
    forColumnView: false,
  );

  /// Returns cached field definitions for table/column views.
  static Fields<Transaction> get fieldsForColumnView => ensureCachedFieldDefinitionsFromBlueprints<Transaction>(
    cache: _fieldsForColumns,
    instanceFactory: () => Transaction(date: DateTime.now()),
    blueprints: _fieldBlueprints,
    forColumnView: true,
  );

  /// Returns [nativeValue] converted into normalized/default currency.
  double getNormalizedAmount(double nativeValue) {
    return transactionGetNormalizedAmount(this, nativeValue);
  }

  /// Returns investment metadata for this transaction, creating a default one when missing.
  Investment getOrCreateInvestment() {
    return transactionGetOrCreateInvestment(this);
  }

  /// Returns payee or transfer caption text for UI display.
  String getPayeeOrTransferCaption({bool showAccount = false}) {
    return transactionGetPayeeOrTransferCaption(this, showAccount: showAccount);
  }

  /// Returns cached account instance associated with this transaction.
  Account? get instanceOfAccount {
    /// cache instances of related MoneyObjects
    _instanceOfAccount ??= DataAbstract.instance.getAccount(this.fieldAccountId.value) as Account?;
    return _instanceOfAccount as Account?;
  }

  /// Sets cached account instance associated with this transaction.
  set instanceOfAccount(Account? value) {
    _instanceOfAccount = value;
  }

  /// Returns cached transfer linkage, resolving it lazily when needed.
  Transfer? get instanceOfTransfer {
    return transactionResolveInstanceOfTransfer(this);
  }

  /// Sets cached transfer linkage for this transaction.
  set instanceOfTransfer(Transfer? value) {
    cachedTransfer = value;
  }

  /// Returns true when the linked account type is asset.
  bool get isAssetAccount => DataAbstract.instance.isAccountAsset(fieldAccountId.value);

  /// Returns true when category type makes this transaction budget-eligible.
  bool get isCandidateForBudget => this.fieldCategoryId.value != _unsetId && (this.isExpense || this.isIncome);

  /// Returns true when this transaction category is an expense.
  bool get isExpense => DataAbstract.instance.isCategoryExpense(fieldCategoryId.value);

  /// Returns true when this transaction category is an income.
  bool get isIncome => DataAbstract.instance.isCategoryIncome(fieldCategoryId.value);

  /// Returns true if this transaction or any split matches a category in [categoriesToMatch].
  bool isMatchingAnyOfTheseCategories(List<int> categoriesToMatch) {
    return transactionIsMatchingAnyOfTheseCategories(this, categoriesToMatch);
  }

  /// Returns true when this transaction has one or more splits.
  bool get isSplit => this.splits.isNotEmpty;

  /// Returns true when this transaction is linked to a transfer.
  bool get isTransfer => fieldTransfer.value != _unsetId;

  /// Returns one-line description combining payee/transfer and category.
  String get oneLinePayeeAndDescription {
    return transactionOneLinePayeeAndDescription(this);
  }

  /// Returns the resolved payee name for this transaction.
  String get payeeName => DataAbstract.instance.getPayeeName(fieldPayee.value);

  /// Returns related account for transfer transactions.
  dynamic get relatedAccount => (instanceOfTransfer?.relatedTransaction as dynamic)?.instanceOfAccount;

  /// Sorts by date first, then unique id as deterministic tie-breaker.
  static int sortByDateTime(
    dynamic a,
    dynamic b,
    bool ascending,
  ) {
    return transactionSortByDateTime(a as Transaction, b as Transaction, ascending);
  }

  /// Stores current payee/transfer caption into original-payee when empty.
  void stashOriginalPayee() {
    transactionStashOriginalPayee(this);
  }

  Widget _buildStatusButtonToggle() {
    return transactionBuildStatusButtonToggle(this);
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
