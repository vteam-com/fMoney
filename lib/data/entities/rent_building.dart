// ignore_for_file: unnecessary_this
import 'package:collection/collection.dart';
import 'package:money/data/entities/data_abstract.dart';
import 'package:money/data/entities/transaction.dart';
import 'package:money/data/entities/transaction_split.dart';
import 'package:money/data/models/account.dart';
import 'package:money/data/models/rental_unit.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/widgets/adaptive_list/list_item_card.dart';
import 'package:money/widgets/rental_pnl.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';
import 'package:money/widgets/widgets_domain/field_type.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

/*
    SQLite table definition

     0|Id|INT|0||1
     1|Name|nvarchar(255)|1||0
     2|Address|nvarchar(255)|0||0
     3|PurchasedDate|datetime|0||0
     4|PurchasedPrice|money|0||0
     5|LandValue|money|0||0
     6|EstimatedValue|money|0||0
     7|OwnershipName1|nvarchar(255)|0||0
     8|OwnershipName2|nvarchar(255)|0||0
     9|OwnershipPercentage1|money|0||0
    10|OwnershipPercentage2|money|0||0
    11|Note|nvarchar(255)|0||0
    12|CategoryForTaxes|INT|0||0
    13|CategoryForIncome|INT|0||0
    14|CategoryForInterest|INT|0||0
    15|CategoryForRepairs|INT|0||0
    16|CategoryForMaintenance|INT|0||0
    17|CategoryForManagement|INT|0||0
   */
/// Represents rent building.
class RentBuilding extends DataObject {
  factory RentBuilding.fromJson(final MyJson row, [final DataAbstract? data]) {
    final RentBuilding instance = RentBuilding();
    if (data != null) {
      instance.data = data;
    }

    instance.fieldId.value = row.getInt('Id', -1);
    instance.fieldName.value = row.getString('Name');
    instance.fieldAddress.value = row.getString('Address');
    instance.fieldPurchasedDate.value = row.getDate(
      'PurchasedDate',
      defaultIfNotFound: DateTime.now(),
    );
    instance.fieldPurchasedPrice.value.setAmount(
      row.getDouble('PurchasedPrice'),
    );
    instance.fieldLandValue.value.setAmount(row.getDouble('LandValue'));
    instance.fieldEstimatedValue.value.setAmount(
      row.getDouble('EstimatedValue'),
    );
    instance.fieldOwnershipName1.value = row.getString('OwnershipName1');
    instance.fieldOwnershipName2.value = row.getString('OwnershipName2');
    instance.fieldOwnershipPercentage1.value = row.getDouble(
      'OwnershipPercentage1',
    );
    instance.fieldOwnershipPercentage2.value = row.getDouble(
      'OwnershipPercentage2',
    );

    instance.categoryForIncome.value = row.getInt('CategoryForIncome', -1);
    if (data != null) {
      instance.categoryForIncomeTreeIds = data.getCategoryTreeIds(
        instance.categoryForIncome.value,
      );
    }

    instance.categoryForTaxes.value = row.getInt('CategoryForTaxes', -1);
    if (data != null) {
      instance.categoryForTaxesTreeIds = data.getCategoryTreeIds(
        instance.categoryForTaxes.value,
      );
    }

    instance.categoryForInterest.value = row.getInt('CategoryForInterest', -1);
    if (data != null) {
      instance.categoryForInterestTreeIds = data.getCategoryTreeIds(
        instance.categoryForInterest.value,
      );
    }

    instance.categoryForRepairs.value = row.getInt('CategoryForRepairs', -1);
    if (data != null) {
      instance.categoryForRepairsTreeIds = data.getCategoryTreeIds(
        instance.categoryForRepairs.value,
      );
    }

    instance.categoryForMaintenance.value = row.getInt(
      'CategoryForMaintenance',
      -1,
    );
    if (data != null) {
      instance.categoryForMaintenanceTreeIds = data.getCategoryTreeIds(
        instance.categoryForMaintenance.value,
      );
    }

    instance.categoryForManagement.value = row.getInt(
      'CategoryForManagement',
      -1,
    );
    if (data != null) {
      instance.categoryForManagementTreeIds = data.getCategoryTreeIds(
        instance.categoryForManagement.value,
      );
    }

    if (data != null) {
      instance.listOfCategoryIdsExpenses.addAll(instance.categoryForTaxesTreeIds);
      instance.listOfCategoryIdsExpenses.addAll(
        instance.categoryForMaintenanceTreeIds,
      );
      instance.listOfCategoryIdsExpenses.addAll(
        instance.categoryForManagementTreeIds,
      );
      instance.listOfCategoryIdsExpenses.addAll(
        instance.categoryForRepairsTreeIds,
      );
      instance.listOfCategoryIdsExpenses.addAll(
        instance.categoryForInterestTreeIds,
      );
    }

    instance.note.value = row.getString('Note');

    return instance;
  }
  RentBuilding();

  late DataAbstract data;

  /// CategoryForIncome
  // 13    CategoryForIncome          money
  FieldInt categoryForIncome = FieldInt(
    name: 'CategoryForIncome',
    serializeName: 'CategoryForIncome',
    getValueForDisplay: (final DataInterface instance) =>
        (instance as RentBuilding).getCategoryName(instance.categoryForIncome.value),
    getValueForSerialization: (final DataInterface instance) => (instance as RentBuilding).categoryForIncome.value,
  );

  List<int> categoryForIncomeTreeIds = <int>[];

  /// CategoryForInterest
  // 14    CategoryForInterest          money
  FieldInt categoryForInterest = FieldInt(
    name: 'CategoryForInterest',
    serializeName: 'CategoryForInterest',
    getValueForDisplay: (final DataInterface instance) =>
        (instance as RentBuilding).getCategoryName(instance.categoryForInterest.value),
    getValueForSerialization: (final DataInterface instance) => (instance as RentBuilding).categoryForInterest.value,
  );

  List<int> categoryForInterestTreeIds = <int>[];

  /// CategoryForMaintenance
  // 16    CategoryForMaintenance          money
  FieldInt categoryForMaintenance = FieldInt(
    name: 'CategoryForMaintenance',
    serializeName: 'CategoryForMaintenance',
    getValueForDisplay: (final DataInterface instance) =>
        (instance as RentBuilding).getCategoryName(instance.categoryForMaintenance.value),
    getValueForSerialization: (final DataInterface instance) => (instance as RentBuilding).categoryForMaintenance.value,
  );

  List<int> categoryForMaintenanceTreeIds = <int>[];

  /// CategoryForManagement
  // 17    CategoryForManagement          money
  FieldInt categoryForManagement = FieldInt(
    name: 'CategoryForManagement',
    serializeName: 'CategoryForManagement',
    getValueForDisplay: (final DataInterface instance) =>
        (instance as RentBuilding).getCategoryName(instance.categoryForManagement.value),
    getValueForSerialization: (final DataInterface instance) => (instance as RentBuilding).categoryForManagement.value,
  );

  List<int> categoryForManagementTreeIds = <int>[];

  /// CategoryForRepairs
  // 15    CategoryForRepairs          money
  FieldInt categoryForRepairs = FieldInt(
    name: 'CategoryForRepairs',
    serializeName: 'CategoryForRepairs',
    getValueForDisplay: (final DataInterface instance) =>
        (instance as RentBuilding).getCategoryName(instance.categoryForRepairs.value),
    getValueForSerialization: (final DataInterface instance) => (instance as RentBuilding).categoryForRepairs.value,
  );

  List<int> categoryForRepairsTreeIds = <int>[];

  /// CategoryForTaxes
  // 12    CategoryForTaxes          money
  FieldInt categoryForTaxes = FieldInt(
    name: 'CategoryForTaxes',
    serializeName: 'CategoryForTaxes',
    getValueForDisplay: (final DataInterface instance) =>
        (instance as RentBuilding).getCategoryName(instance.categoryForTaxes.value),
    getValueForSerialization: (final DataInterface instance) => (instance as RentBuilding).categoryForTaxes.value,
  );

  List<int> categoryForTaxesTreeIds = <int>[];
  DateRange dateRangeOfOperation = DateRange();

  /// Address
  // 2    Address                 nvarchar(255)  0                    0
  FieldString fieldAddress = FieldString(
    name: 'Address',
    serializeName: 'Address',
    getValueForDisplay: (final DataInterface instance) => (instance as RentBuilding).fieldAddress.value,
    getValueForSerialization: (final DataInterface instance) => (instance as RentBuilding).fieldAddress.value,
  );

  /// Currency
  FieldString fieldCurrency = FieldString(
    name: 'Currency',
    type: FieldType.widget,
    align: TextAlign.center,
    columnWidth: ColumnWidth.nano,
    getValueForReading: (final DataInterface instance) => (instance as RentBuilding).getCurrencyOfAssociatedAccount(),
    getValueForDisplay: (final DataInterface instance) => buildCurrencyWidget(
      (instance as RentBuilding).getCurrencyOfAssociatedAccount(),
    ),
  );

  /// EstimatedValue
  // 6    EstimatedValue          money
  FieldMoney fieldEstimatedValue = FieldMoney(
    name: 'EstimatedValue',
    serializeName: 'EstimatedValue',
    getValueForDisplay: (final DataInterface instance) => (instance as RentBuilding).fieldEstimatedValue.value,
    getValueForSerialization: (final DataInterface instance) =>
        (instance as RentBuilding).fieldEstimatedValue.value.asDouble(),
    setValue: (final DataInterface instance, final dynamic value) =>
        (instance as RentBuilding).fieldEstimatedValue.setAmount(value),
  );

  /// Expenses
  FieldMoney fieldExpense = FieldMoney(
    name: 'Expenses',
    getValueForDisplay: (final DataInterface instance) =>
        AmountModel(amount: (instance as RentBuilding).lifeTimePnL.expenses),
  );

  /// ID
  // 0    Id                      INT            0                    1
  FieldId fieldId = FieldId(
    getValueForSerialization: (final DataInterface instance) => (instance as RentBuilding).uniqueId,
  );

  /// LandValue
  // 5    LandValue          money
  FieldMoney fieldLandValue = FieldMoney(
    name: 'LandValue',
    serializeName: 'LandValue',
    getValueForDisplay: (final DataInterface instance) => (instance as RentBuilding).fieldLandValue.value,
    getValueForSerialization: (final DataInterface instance) =>
        (instance as RentBuilding).fieldLandValue.value.asDouble(),
    setValue: (final DataInterface instance, final dynamic value) =>
        (instance as RentBuilding).fieldLandValue.setAmount(value),
  );

  /// Expenses-Interest
  FieldMoney fieldLifeTimeExpenseInterest = FieldMoney(
    name: '  Expense-Interest',
    getValueForDisplay: (final DataInterface instance) => AmountModel(
      amount: (instance as RentBuilding).lifeTimePnL.expenseInterest,
    ),
  );

  /// Expenses-Maintenance
  FieldMoney fieldLifeTimeExpenseMaintenance = FieldMoney(
    name: '  Expense-Maintenance',
    getValueForDisplay: (final DataInterface instance) => AmountModel(
      amount: (instance as RentBuilding).lifeTimePnL.expenseMaintenance,
    ),
  );

  /// Expenses-Management
  FieldMoney fieldLifeTimeExpenseManagement = FieldMoney(
    name: '  Expense-Management',
    getValueForDisplay: (final DataInterface instance) => AmountModel(
      amount: (instance as RentBuilding).lifeTimePnL.expenseManagement,
    ),
  );

  /// Expenses-Repair
  FieldMoney fieldLifeTimeExpenseRepair = FieldMoney(
    name: '  Expense-Repair',
    getValueForDisplay: (final DataInterface instance) => AmountModel(
      amount: (instance as RentBuilding).lifeTimePnL.expenseRepairs,
    ),
  );

  /// Expenses-Taxes
  FieldMoney fieldLifeTimeExpenseTaxes = FieldMoney(
    name: '  Expense-Taxes',
    getValueForDisplay: (final DataInterface instance) => AmountModel(
      amount: (instance as RentBuilding).lifeTimePnL.expenseTaxes,
    ),
  );

  /// Name
  // 1    Name                    nvarchar(255)  1                    0
  FieldString fieldName = FieldString(
    name: 'Name',
    serializeName: 'Name',
    getValueForDisplay: (final DataInterface instance) => (instance as RentBuilding).fieldName.value,
    getValueForSerialization: (final DataInterface instance) => (instance as RentBuilding).fieldName.value,
  );

  /// OwnershipName1
  // 7    OwnershipName1          money
  FieldString fieldOwnershipName1 = FieldString(
    name: 'OwnershipName1',
    serializeName: 'OwnershipName1',
    getValueForDisplay: (final DataInterface instance) => (instance as RentBuilding).fieldOwnershipName1.value,
    getValueForSerialization: (final DataInterface instance) => (instance as RentBuilding).fieldOwnershipName1.value,
  );

  /// OwnershipName2
  // 8    OwnershipName2          money
  FieldString fieldOwnershipName2 = FieldString(
    name: 'OwnershipName2',
    serializeName: 'OwnershipName2',
    getValueForDisplay: (final DataInterface instance) => (instance as RentBuilding).fieldOwnershipName2.value,
    getValueForSerialization: (final DataInterface instance) => (instance as RentBuilding).fieldOwnershipName2.value,
  );

  /// OwnershipPercentage1
  // 9    OwnershipPercentage1          money
  FieldDouble fieldOwnershipPercentage1 = FieldDouble(
    name: 'OwnershipPercentage1',
    serializeName: 'OwnershipPercentage1',
    getValueForDisplay: (final DataInterface instance) => (instance as RentBuilding).fieldOwnershipPercentage1.value,
    getValueForSerialization: (final DataInterface instance) =>
        (instance as RentBuilding).fieldOwnershipPercentage1.value,
  );

  /// OwnershipPercentage2
  // 10    OwnershipPercentage2          money
  FieldDouble fieldOwnershipPercentage2 = FieldDouble(
    name: 'OwnershipPercentage2',
    serializeName: 'OwnershipPercentage2',
    getValueForDisplay: (final DataInterface instance) => (instance as RentBuilding).fieldOwnershipPercentage2.value,
    getValueForSerialization: (final DataInterface instance) =>
        (instance as RentBuilding).fieldOwnershipPercentage2.value,
  );

  /// Profit
  FieldMoney fieldProfit = FieldMoney(
    name: 'Profit',
    getValueForDisplay: (final DataInterface instance) =>
        AmountModel(amount: (instance as RentBuilding).lifeTimePnL.profit),
  );

  /// PurchasedDate
  // 3    PurchasedDate           datetime       0                    0
  FieldDate fieldPurchasedDate = FieldDate(
    name: 'Purchased Date',
    serializeName: 'PurchasedDate',
    getValueForDisplay: (final DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as RentBuilding).fieldPurchasedDate.value,
    ),
    getValueForSerialization: (final DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as RentBuilding).fieldPurchasedDate.value,
    ),
  );

  /// PurchasedPrice
  // 4    PurchasedPrice          money
  FieldMoney fieldPurchasedPrice = FieldMoney(
    name: 'Purchased Price',
    serializeName: 'PurchasedPrice',
    getValueForDisplay: (final DataInterface instance) => (instance as RentBuilding).fieldPurchasedPrice.value,
    getValueForSerialization: (final DataInterface instance) =>
        (instance as RentBuilding).fieldPurchasedPrice.value.asDouble(),
  );

  /// Revenue
  FieldMoney fieldRevenue = FieldMoney(
    name: 'Revenue',
    getValueForDisplay: (final DataInterface instance) =>
        AmountModel(amount: (instance as RentBuilding).lifeTimePnL.income),
  );

  FieldInt fieldTransactionsForExpenses = FieldInt(
    name: 'E#',
    getValueForDisplay: (final DataInterface instance) => (instance as RentBuilding).fieldTransactionsForExpenses.value,
  );

  FieldInt fieldTransactionsForIncomes = FieldInt(
    name: 'I#',
    getValueForDisplay: (final DataInterface instance) => (instance as RentBuilding).fieldTransactionsForIncomes.value,
  );

  late RentalPnL lifeTimePnL;
  List<int> listOfCategoryIdsExpenses = <int>[];

  /// Note
  // 11    Note          money
  FieldString note = FieldString(
    name: 'Note',
    serializeName: 'Note',
    getValueForDisplay: (final DataInterface instance) => (instance as RentBuilding).note.value,
    getValueForSerialization: (final DataInterface instance) => (instance as RentBuilding).note.value,
  );

  Map<int, RentalPnL> pnlOverYears = <int, RentalPnL>{};
  List<RentUnit> units = <RentUnit>[];

  Account? account;

  @override
  Widget buildFieldsAsWidgetForSmallScreen() {
    return MyListItemAsCard(
      leftTopAsString: fieldName.value,
      leftBottomAsString: fieldAddress.value,
      rightTopAsWidget: WidgetFromData(
        amountModel: AmountModel(amount: lifeTimePnL.profit),
        size: DataWidgetSize.title,
      ),
    );
  }

  // Fields for this instance
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(final int value) => fieldId.value = value;

  static final Fields<RentBuilding> _fields = Fields<RentBuilding>();

  /// Attempts to associate this rental with an account by looking for the first matching income transaction.
  void associateAccountToBuilding() {
    final dynamic firstTransactionForThisBuilding = data
        .getTransactions(includeDeleted: true)
        .firstWhereOrNull(
          (dynamic t) => this.categoryForIncomeTreeIds.contains((t as Transaction).fieldCategoryId.value),
        );
    if (firstTransactionForThisBuilding != null) {
      this.account = (firstTransactionForThisBuilding as Transaction).instanceOfAccount;
    }
  }

  /// Updates year-based and lifetime profit-and-loss using the given transaction.
  void cumulatePnL(Transaction t) {
    final int transactionCategoryId = t.fieldCategoryId.value;

    if (this.isTransactionOrSplitAssociatedWithThisRental(t)) {
      final int year = t.fieldDateTime.value!.year;

      RentalPnL? pnl = pnlOverYears[year];
      if (pnl == null) {
        pnl = RentalPnL(
          date: t.fieldDateTime.value!,
          currency: getCurrencyOfAssociatedAccount(),
        );

        if (this.fieldOwnershipName1.value.isNotEmpty) {
          final String name = '${this.fieldOwnershipName1.value} (${fieldOwnershipPercentage1.value}%)';
          pnl.distributions[name] = this.fieldOwnershipPercentage1.value;
        }

        if (this.fieldOwnershipName2.value.isNotEmpty) {
          final String name = '${this.fieldOwnershipName2.value} (${fieldOwnershipPercentage2.value}%)';
          pnl.distributions[name] = this.fieldOwnershipPercentage2.value;
        }

        pnlOverYears[year] = pnl;
      }

      if (t.isSplit) {
        for (final TransactionSplit split in t.splits) {
          cumulatePnLValues(
            pnl,
            split.fieldCategoryId.value,
            split.fieldAmount.value.asDouble(),
          );
        }
      } else {
        cumulatePnLValues(
          pnl,
          transactionCategoryId,
          t.fieldAmount.value.asDouble(),
        );
      }
    }

    lifeTimePnL = getLifeTimePnL();
  }

  /// Applies a single income/expense amount to the correct PnL buckets.
  void cumulatePnLValues(RentalPnL pnl, int categoryId, double amount) {
    if (this.categoryForIncomeTreeIds.contains(categoryId)) {
      fieldTransactionsForIncomes.value++;
      pnl.income += amount;
    }

    if (this.categoryForInterestTreeIds.contains(categoryId)) {
      fieldTransactionsForExpenses.value++;
      pnl.expenseInterest += amount;
    }
    if (this.categoryForRepairsTreeIds.contains(categoryId)) {
      fieldTransactionsForExpenses.value++;
      pnl.expenseRepairs += amount;
    }
    if (this.categoryForMaintenanceTreeIds.contains(categoryId)) {
      fieldTransactionsForExpenses.value++;
      pnl.expenseMaintenance += amount;
    }
    if (this.categoryForManagementTreeIds.contains(categoryId)) {
      fieldTransactionsForExpenses.value++;
      pnl.expenseManagement += amount;
    }
    if (this.categoryForTaxesTreeIds.contains(categoryId)) {
      fieldTransactionsForExpenses.value++;
      pnl.expenseTaxes += amount;
    }
  }

  /// Returns the field definitions for RentBuilding entities.
  static Fields<RentBuilding> get fields {
    if (_fields.isEmpty) {
      final RentBuilding tmp = RentBuilding.fromJson(<String, dynamic>{});
      _fields.setDefinitions(<Field<dynamic>>[
        tmp.fieldId,
        tmp.fieldName,
        tmp.fieldAddress,
        tmp.fieldCurrency,
        tmp.fieldPurchasedDate,
        tmp.fieldPurchasedPrice,
        tmp.fieldLandValue,
        tmp.fieldEstimatedValue,
        tmp.fieldOwnershipName1,
        tmp.fieldOwnershipPercentage1,
        tmp.fieldOwnershipName2,
        tmp.fieldOwnershipPercentage2,
        tmp.categoryForIncome,
        tmp.categoryForInterest,
        tmp.categoryForManagement,
        tmp.categoryForMaintenance,
        tmp.categoryForRepairs,
        tmp.categoryForTaxes,
        tmp.fieldTransactionsForIncomes,
        tmp.fieldRevenue,
        tmp.fieldTransactionsForExpenses,
        tmp.fieldExpense,
        tmp.fieldLifeTimeExpenseInterest,
        tmp.fieldLifeTimeExpenseMaintenance,
        tmp.fieldLifeTimeExpenseManagement,
        tmp.fieldLifeTimeExpenseRepair,
        tmp.fieldLifeTimeExpenseTaxes,
        tmp.fieldProfit,
      ]);
    }
    return _fields;
  }

  /// Returns the field definitions for RentBuilding column view.
  static Fields<RentBuilding> get fieldsForColumnView {
    final RentBuilding tmp = RentBuilding.fromJson(<String, dynamic>{});
    return Fields<RentBuilding>()..setDefinitions(<Field<dynamic>>[
      tmp.fieldName,
      tmp.fieldAddress,
      tmp.fieldCurrency,
      tmp.fieldLandValue,
      tmp.fieldEstimatedValue,
      tmp.fieldTransactionsForIncomes,
      tmp.fieldRevenue,
      tmp.fieldTransactionsForExpenses,
      tmp.fieldExpense,
      tmp.fieldLifeTimeExpenseInterest,
      tmp.fieldLifeTimeExpenseMaintenance,
      tmp.fieldLifeTimeExpenseManagement,
      tmp.fieldLifeTimeExpenseRepair,
      tmp.fieldLifeTimeExpenseTaxes,
      tmp.fieldProfit,
    ]);
  }

  /// Returns the category name for the given category [id].
  String getCategoryName(final int id) {
    return data.getCategoryNameFromId(id);
  }

  /// Returns the currency of the associated account or the default currency.
  String getCurrencyOfAssociatedAccount() {
    if (this.account == null) {
      return Constants.defaultCurrency;
    } else {
      return account!.fieldCurrency.value;
    }
  }

  /// Returns lifetime profit-and-loss accumulated across all years.
  RentalPnL getLifeTimePnL() {
    final RentalPnL lifeTimePnL = RentalPnL(date: DateTime.now());
    pnlOverYears.forEach((int _ /* year */, RentalPnL pnl) {
      dateRangeOfOperation.inflate(pnl.date);
      lifeTimePnL.income += pnl.income;
      lifeTimePnL.expenseInterest += pnl.expenseInterest;
      lifeTimePnL.expenseManagement += pnl.expenseManagement;
      lifeTimePnL.expenseMaintenance += pnl.expenseMaintenance;
      lifeTimePnL.expenseRepairs += pnl.expenseRepairs;
      lifeTimePnL.expenseTaxes += pnl.expenseTaxes;
      lifeTimePnL.currency = pnl.currency;
      lifeTimePnL.distributions = pnl.distributions;
    });
    return lifeTimePnL;
  }

  /// Returns true if a transaction category is associated with this rental.
  bool isTransactionAssociatedWithThisRental(int transactionCategoryId) {
    return this.categoryForIncomeTreeIds.contains(transactionCategoryId) ||
        this.categoryForInterestTreeIds.contains(transactionCategoryId) ||
        this.categoryForRepairsTreeIds.contains(transactionCategoryId) ||
        this.categoryForMaintenanceTreeIds.contains(transactionCategoryId) ||
        this.categoryForManagementTreeIds.contains(transactionCategoryId) ||
        this.categoryForTaxesTreeIds.contains(transactionCategoryId);
  }

  /// Returns true if a transaction or any split is associated with this rental.
  bool isTransactionOrSplitAssociatedWithThisRental(Transaction t) {
    final int transactionCategoryId = t.fieldCategoryId.value;
    if (t.isSplit) {
      for (final TransactionSplit split in t.splits) {
        if (isTransactionAssociatedWithThisRental(
          split.fieldCategoryId.value,
        )) {
          return true;
        }
      }
      return false;
    } else {
      return isTransactionAssociatedWithThisRental(transactionCategoryId);
    }
  }
}
