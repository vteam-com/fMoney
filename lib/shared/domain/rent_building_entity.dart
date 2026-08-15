// ignore_for_file: unnecessary_this
import 'package:collection/collection.dart';
import 'package:money/data/models/field_type_enum.dart';
import 'package:money/data/models/ranges_model.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/field_definition_cache_helper.dart';
import 'package:money/shared/domain/rental_unit_entity.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/shared/domain/transaction_split_entity.dart';
import 'package:money/widgets/components/rental_pnl_widget.dart';
import 'package:money/widgets/list/list_item_card.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';
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
  factory RentBuilding.fromJson(MyJson row, [DataAbstract? data]) {
    final RentBuilding instance = RentBuilding();
    if (data != null) {
      instance.data = data;
    }

    instance.fieldId.value = row.getInt(SharedDomainStrings.domainString057, -1);
    instance.fieldName.value = row.getString(SharedDomainStrings.domainString088);
    instance.fieldAddress.value = row.getString(SharedDomainStrings.domainString015);
    instance.fieldPurchasedDate.value = row.getDate(
      SharedDomainStrings.domainString111,
      defaultIfNotFound: DateTime.now(),
    );
    instance.fieldPurchasedPrice.value.setAmount(
      row.getDouble(SharedDomainStrings.domainString112),
    );
    instance.fieldLandValue.value.setAmount(row.getDouble(SharedDomainStrings.domainString077));
    instance.fieldEstimatedValue.value.setAmount(
      row.getDouble(SharedDomainStrings.domainString049),
    );
    instance.fieldOwnershipName1.value = row.getString('OwnershipName1');
    instance.fieldOwnershipName2.value = row.getString('OwnershipName2');
    instance.fieldOwnershipPercentage1.value = row.getDouble(
      'OwnershipPercentage1',
    );
    instance.fieldOwnershipPercentage2.value = row.getDouble(
      'OwnershipPercentage2',
    );

    instance.categoryForIncome.value = row.getInt(SharedDomainStrings.domainString030, -1);
    if (data != null) {
      instance.categoryForIncomeTreeIds = data.getCategoryTreeIds(
        instance.categoryForIncome.value,
      );
    }

    instance.categoryForTaxes.value = row.getInt(SharedDomainStrings.domainString035, -1);
    if (data != null) {
      instance.categoryForTaxesTreeIds = data.getCategoryTreeIds(
        instance.categoryForTaxes.value,
      );
    }

    instance.categoryForInterest.value = row.getInt(SharedDomainStrings.domainString031, -1);
    if (data != null) {
      instance.categoryForInterestTreeIds = data.getCategoryTreeIds(
        instance.categoryForInterest.value,
      );
    }

    instance.categoryForRepairs.value = row.getInt(SharedDomainStrings.domainString034, -1);
    if (data != null) {
      instance.categoryForRepairsTreeIds = data.getCategoryTreeIds(
        instance.categoryForRepairs.value,
      );
    }

    instance.categoryForMaintenance.value = row.getInt(
      SharedDomainStrings.domainString032,
      -1,
    );
    if (data != null) {
      instance.categoryForMaintenanceTreeIds = data.getCategoryTreeIds(
        instance.categoryForMaintenance.value,
      );
    }

    instance.categoryForManagement.value = row.getInt(
      SharedDomainStrings.domainString033,
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

    instance.note.value = row.getString(SharedDomainStrings.domainString091);

    return instance;
  }
  RentBuilding();

  late DataAbstract data;

  /// CategoryForIncome
  // 13    CategoryForIncome          money
  FieldInt categoryForIncome = FieldInt(
    name: SharedDomainStrings.domainString030,
    serializeName: SharedDomainStrings.domainString030,
    getValueForDisplay: (DataInterface instance) =>
        (instance as RentBuilding).getCategoryName(instance.categoryForIncome.value),
    getValueForSerialization: (DataInterface instance) => (instance as RentBuilding).categoryForIncome.value,
  );

  List<int> categoryForIncomeTreeIds = <int>[];

  /// CategoryForInterest
  // 14    CategoryForInterest          money
  FieldInt categoryForInterest = FieldInt(
    name: SharedDomainStrings.domainString031,
    serializeName: SharedDomainStrings.domainString031,
    getValueForDisplay: (DataInterface instance) =>
        (instance as RentBuilding).getCategoryName(instance.categoryForInterest.value),
    getValueForSerialization: (DataInterface instance) => (instance as RentBuilding).categoryForInterest.value,
  );

  List<int> categoryForInterestTreeIds = <int>[];

  /// CategoryForMaintenance
  // 16    CategoryForMaintenance          money
  FieldInt categoryForMaintenance = FieldInt(
    name: SharedDomainStrings.domainString032,
    serializeName: SharedDomainStrings.domainString032,
    getValueForDisplay: (DataInterface instance) =>
        (instance as RentBuilding).getCategoryName(instance.categoryForMaintenance.value),
    getValueForSerialization: (DataInterface instance) => (instance as RentBuilding).categoryForMaintenance.value,
  );

  List<int> categoryForMaintenanceTreeIds = <int>[];

  /// CategoryForManagement
  // 17    CategoryForManagement          money
  FieldInt categoryForManagement = FieldInt(
    name: SharedDomainStrings.domainString033,
    serializeName: SharedDomainStrings.domainString033,
    getValueForDisplay: (DataInterface instance) =>
        (instance as RentBuilding).getCategoryName(instance.categoryForManagement.value),
    getValueForSerialization: (DataInterface instance) => (instance as RentBuilding).categoryForManagement.value,
  );

  List<int> categoryForManagementTreeIds = <int>[];

  /// CategoryForRepairs
  // 15    CategoryForRepairs          money
  FieldInt categoryForRepairs = FieldInt(
    name: SharedDomainStrings.domainString034,
    serializeName: SharedDomainStrings.domainString034,
    getValueForDisplay: (DataInterface instance) =>
        (instance as RentBuilding).getCategoryName(instance.categoryForRepairs.value),
    getValueForSerialization: (DataInterface instance) => (instance as RentBuilding).categoryForRepairs.value,
  );

  List<int> categoryForRepairsTreeIds = <int>[];

  /// CategoryForTaxes
  // 12    CategoryForTaxes          money
  FieldInt categoryForTaxes = FieldInt(
    name: SharedDomainStrings.domainString035,
    serializeName: SharedDomainStrings.domainString035,
    getValueForDisplay: (DataInterface instance) =>
        (instance as RentBuilding).getCategoryName(instance.categoryForTaxes.value),
    getValueForSerialization: (DataInterface instance) => (instance as RentBuilding).categoryForTaxes.value,
  );

  List<int> categoryForTaxesTreeIds = <int>[];
  DateRange dateRangeOfOperation = DateRange();

  /// Address
  // 2    Address                 nvarchar(255)  0                    0
  FieldString fieldAddress = FieldString(
    name: SharedDomainStrings.domainString015,
    serializeName: SharedDomainStrings.domainString015,
    getValueForDisplay: (DataInterface instance) => (instance as RentBuilding).fieldAddress.value,
    getValueForSerialization: (DataInterface instance) => (instance as RentBuilding).fieldAddress.value,
  );

  /// Currency
  FieldString fieldCurrency = FieldString(
    name: SharedDomainStrings.domainString042,
    type: FieldType.widget,
    align: TextAlign.center,
    columnWidth: ColumnWidth.nano,
    getValueForReading: (DataInterface instance) => (instance as RentBuilding).getCurrencyOfAssociatedAccount(),
    getValueForDisplay: (DataInterface instance) => buildCurrencyWidget(
      (instance as RentBuilding).getCurrencyOfAssociatedAccount(),
    ),
  );

  /// EstimatedValue
  // 6    EstimatedValue          money
  FieldMoney fieldEstimatedValue = FieldMoney(
    name: SharedDomainStrings.domainString049,
    serializeName: SharedDomainStrings.domainString049,
    getValueForDisplay: (DataInterface instance) => (instance as RentBuilding).fieldEstimatedValue.value,
    getValueForSerialization: (DataInterface instance) =>
        (instance as RentBuilding).fieldEstimatedValue.value.asDouble(),
    setValue: (DataInterface instance, dynamic value) =>
        (instance as RentBuilding).fieldEstimatedValue.setAmount(value),
  );

  /// Expenses
  FieldMoney fieldExpense = FieldMoney(
    name: 'Expenses',
    getValueForDisplay: (DataInterface instance) =>
        AmountModel(amount: (instance as RentBuilding).lifeTimePnL.expenses),
  );

  /// ID
  // 0    Id                      INT            0                    1
  FieldId fieldId = FieldId(
    getValueForSerialization: (DataInterface instance) => (instance as RentBuilding).uniqueId,
  );

  /// LandValue
  // 5    LandValue          money
  FieldMoney fieldLandValue = FieldMoney(
    name: SharedDomainStrings.domainString077,
    serializeName: SharedDomainStrings.domainString077,
    getValueForDisplay: (DataInterface instance) => (instance as RentBuilding).fieldLandValue.value,
    getValueForSerialization: (DataInterface instance) => (instance as RentBuilding).fieldLandValue.value.asDouble(),
    setValue: (DataInterface instance, dynamic value) => (instance as RentBuilding).fieldLandValue.setAmount(value),
  );

  /// Expenses-Interest
  FieldMoney fieldLifeTimeExpenseInterest = FieldMoney(
    name: '  Expense-Interest',
    getValueForDisplay: (DataInterface instance) => AmountModel(
      amount: (instance as RentBuilding).lifeTimePnL.expenseInterest,
    ),
  );

  /// Expenses-Maintenance
  FieldMoney fieldLifeTimeExpenseMaintenance = FieldMoney(
    name: '  Expense-Maintenance',
    getValueForDisplay: (DataInterface instance) => AmountModel(
      amount: (instance as RentBuilding).lifeTimePnL.expenseMaintenance,
    ),
  );

  /// Expenses-Management
  FieldMoney fieldLifeTimeExpenseManagement = FieldMoney(
    name: '  Expense-Management',
    getValueForDisplay: (DataInterface instance) => AmountModel(
      amount: (instance as RentBuilding).lifeTimePnL.expenseManagement,
    ),
  );

  /// Expenses-Repair
  FieldMoney fieldLifeTimeExpenseRepair = FieldMoney(
    name: '  Expense-Repair',
    getValueForDisplay: (DataInterface instance) => AmountModel(
      amount: (instance as RentBuilding).lifeTimePnL.expenseRepairs,
    ),
  );

  /// Expenses-Taxes
  FieldMoney fieldLifeTimeExpenseTaxes = FieldMoney(
    name: '  Expense-Taxes',
    getValueForDisplay: (DataInterface instance) => AmountModel(
      amount: (instance as RentBuilding).lifeTimePnL.expenseTaxes,
    ),
  );

  /// Name
  // 1    Name                    nvarchar(255)  1                    0
  FieldString fieldName = FieldString(
    name: SharedDomainStrings.domainString088,
    serializeName: SharedDomainStrings.domainString088,
    getValueForDisplay: (DataInterface instance) => (instance as RentBuilding).fieldName.value,
    getValueForSerialization: (DataInterface instance) => (instance as RentBuilding).fieldName.value,
  );

  /// OwnershipName1
  // 7    OwnershipName1          money
  FieldString fieldOwnershipName1 = FieldString(
    name: 'OwnershipName1',
    serializeName: 'OwnershipName1',
    getValueForDisplay: (DataInterface instance) => (instance as RentBuilding).fieldOwnershipName1.value,
    getValueForSerialization: (DataInterface instance) => (instance as RentBuilding).fieldOwnershipName1.value,
  );

  /// OwnershipName2
  // 8    OwnershipName2          money
  FieldString fieldOwnershipName2 = FieldString(
    name: 'OwnershipName2',
    serializeName: 'OwnershipName2',
    getValueForDisplay: (DataInterface instance) => (instance as RentBuilding).fieldOwnershipName2.value,
    getValueForSerialization: (DataInterface instance) => (instance as RentBuilding).fieldOwnershipName2.value,
  );

  /// OwnershipPercentage1
  // 9    OwnershipPercentage1          money
  FieldDouble fieldOwnershipPercentage1 = FieldDouble(
    name: 'OwnershipPercentage1',
    serializeName: 'OwnershipPercentage1',
    getValueForDisplay: (DataInterface instance) => (instance as RentBuilding).fieldOwnershipPercentage1.value,
    getValueForSerialization: (DataInterface instance) => (instance as RentBuilding).fieldOwnershipPercentage1.value,
  );

  /// OwnershipPercentage2
  // 10    OwnershipPercentage2          money
  FieldDouble fieldOwnershipPercentage2 = FieldDouble(
    name: 'OwnershipPercentage2',
    serializeName: 'OwnershipPercentage2',
    getValueForDisplay: (DataInterface instance) => (instance as RentBuilding).fieldOwnershipPercentage2.value,
    getValueForSerialization: (DataInterface instance) => (instance as RentBuilding).fieldOwnershipPercentage2.value,
  );

  /// Profit
  FieldMoney fieldProfit = FieldMoney(
    name: 'Profit',
    getValueForDisplay: (DataInterface instance) => AmountModel(amount: (instance as RentBuilding).lifeTimePnL.profit),
  );

  /// PurchasedDate
  // 3    PurchasedDate           datetime       0                    0
  FieldDate fieldPurchasedDate = FieldDate(
    name: 'Purchased Date',
    serializeName: SharedDomainStrings.domainString111,
    getValueForDisplay: (DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as RentBuilding).fieldPurchasedDate.value,
    ),
    getValueForSerialization: (DataInterface instance) => dateToIso8601OrDefaultString(
      (instance as RentBuilding).fieldPurchasedDate.value,
    ),
  );

  /// PurchasedPrice
  // 4    PurchasedPrice          money
  FieldMoney fieldPurchasedPrice = FieldMoney(
    name: 'Purchased Price',
    serializeName: SharedDomainStrings.domainString112,
    getValueForDisplay: (DataInterface instance) => (instance as RentBuilding).fieldPurchasedPrice.value,
    getValueForSerialization: (DataInterface instance) =>
        (instance as RentBuilding).fieldPurchasedPrice.value.asDouble(),
  );

  /// Revenue
  FieldMoney fieldRevenue = FieldMoney(
    name: 'Revenue',
    getValueForDisplay: (DataInterface instance) => AmountModel(amount: (instance as RentBuilding).lifeTimePnL.income),
  );

  FieldInt fieldTransactionsForExpenses = FieldInt(
    name: 'E#',
    getValueForDisplay: (DataInterface instance) => (instance as RentBuilding).fieldTransactionsForExpenses.value,
  );

  FieldInt fieldTransactionsForIncomes = FieldInt(
    name: 'I#',
    getValueForDisplay: (DataInterface instance) => (instance as RentBuilding).fieldTransactionsForIncomes.value,
  );

  late RentalPnL lifeTimePnL;
  List<int> listOfCategoryIdsExpenses = <int>[];

  /// Note
  // 11    Note          money
  FieldString note = FieldString(
    name: SharedDomainStrings.domainString091,
    serializeName: SharedDomainStrings.domainString091,
    getValueForDisplay: (DataInterface instance) => (instance as RentBuilding).note.value,
    getValueForSerialization: (DataInterface instance) => (instance as RentBuilding).note.value,
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
  set uniqueId(int value) => fieldId.value = value;

  static final Fields<RentBuilding> _fields = Fields<RentBuilding>();
  static final Fields<RentBuilding> _fieldsForColumns = Fields<RentBuilding>();
  static final List<FieldBlueprint<RentBuilding>> _fieldBlueprints = <FieldBlueprint<RentBuilding>>[
    FieldBlueprint<RentBuilding>(selector: (RentBuilding tmp) => tmp.fieldId),
    FieldBlueprint<RentBuilding>(selector: (RentBuilding tmp) => tmp.fieldName, includeInColumnView: true),
    FieldBlueprint<RentBuilding>(
      selector: (RentBuilding tmp) => tmp.fieldAddress,
      includeInColumnView: true,
    ),
    FieldBlueprint<RentBuilding>(
      selector: (RentBuilding tmp) => tmp.fieldCurrency,
      includeInColumnView: true,
    ),
    FieldBlueprint<RentBuilding>(selector: (RentBuilding tmp) => tmp.fieldPurchasedDate),
    FieldBlueprint<RentBuilding>(selector: (RentBuilding tmp) => tmp.fieldPurchasedPrice),
    FieldBlueprint<RentBuilding>(
      selector: (RentBuilding tmp) => tmp.fieldLandValue,
      includeInColumnView: true,
    ),
    FieldBlueprint<RentBuilding>(
      selector: (RentBuilding tmp) => tmp.fieldEstimatedValue,
      includeInColumnView: true,
    ),
    FieldBlueprint<RentBuilding>(selector: (RentBuilding tmp) => tmp.fieldOwnershipName1),
    FieldBlueprint<RentBuilding>(selector: (RentBuilding tmp) => tmp.fieldOwnershipPercentage1),
    FieldBlueprint<RentBuilding>(selector: (RentBuilding tmp) => tmp.fieldOwnershipName2),
    FieldBlueprint<RentBuilding>(selector: (RentBuilding tmp) => tmp.fieldOwnershipPercentage2),
    FieldBlueprint<RentBuilding>(selector: (RentBuilding tmp) => tmp.categoryForIncome),
    FieldBlueprint<RentBuilding>(selector: (RentBuilding tmp) => tmp.categoryForInterest),
    FieldBlueprint<RentBuilding>(selector: (RentBuilding tmp) => tmp.categoryForManagement),
    FieldBlueprint<RentBuilding>(selector: (RentBuilding tmp) => tmp.categoryForMaintenance),
    FieldBlueprint<RentBuilding>(selector: (RentBuilding tmp) => tmp.categoryForRepairs),
    FieldBlueprint<RentBuilding>(selector: (RentBuilding tmp) => tmp.categoryForTaxes),
    FieldBlueprint<RentBuilding>(
      selector: (RentBuilding tmp) => tmp.fieldTransactionsForIncomes,
      includeInColumnView: true,
    ),
    FieldBlueprint<RentBuilding>(selector: (RentBuilding tmp) => tmp.fieldRevenue, includeInColumnView: true),
    FieldBlueprint<RentBuilding>(
      selector: (RentBuilding tmp) => tmp.fieldTransactionsForExpenses,
      includeInColumnView: true,
    ),
    FieldBlueprint<RentBuilding>(selector: (RentBuilding tmp) => tmp.fieldExpense, includeInColumnView: true),
    FieldBlueprint<RentBuilding>(
      selector: (RentBuilding tmp) => tmp.fieldLifeTimeExpenseInterest,
      includeInColumnView: true,
    ),
    FieldBlueprint<RentBuilding>(
      selector: (RentBuilding tmp) => tmp.fieldLifeTimeExpenseMaintenance,
      includeInColumnView: true,
    ),
    FieldBlueprint<RentBuilding>(
      selector: (RentBuilding tmp) => tmp.fieldLifeTimeExpenseManagement,
      includeInColumnView: true,
    ),
    FieldBlueprint<RentBuilding>(
      selector: (RentBuilding tmp) => tmp.fieldLifeTimeExpenseRepair,
      includeInColumnView: true,
    ),
    FieldBlueprint<RentBuilding>(
      selector: (RentBuilding tmp) => tmp.fieldLifeTimeExpenseTaxes,
      includeInColumnView: true,
    ),
    FieldBlueprint<RentBuilding>(selector: (RentBuilding tmp) => tmp.fieldProfit, includeInColumnView: true),
  ];

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
  static Fields<RentBuilding> get fields => ensureCachedFieldDefinitionsFromBlueprints<RentBuilding>(
    cache: _fields,
    instanceFactory: () => RentBuilding.fromJson(<String, dynamic>{}),
    blueprints: _fieldBlueprints,
    forColumnView: false,
  );

  /// Returns the field definitions for RentBuilding column view.
  static Fields<RentBuilding> get fieldsForColumnView => ensureCachedFieldDefinitionsFromBlueprints<RentBuilding>(
    cache: _fieldsForColumns,
    instanceFactory: () => RentBuilding.fromJson(<String, dynamic>{}),
    blueprints: _fieldBlueprints,
    forColumnView: true,
  );

  /// Returns the category name for the given category [id].
  String getCategoryName(int id) {
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
