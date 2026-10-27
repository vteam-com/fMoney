// Imports
import 'dart:ui' show Color, TextAlign;

import 'package:money/data/helpers/category_type_helper.dart';
import 'package:money/data/models/data_interface.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/data/models/field_type_enum.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/helpers/color_helper.dart' show getColorFromString;
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/pairs_model.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/field_definition_cache_helper.dart';

const int _unsetId = -1;
const int _zeroInt = 0;
const int _levelStep = 1;
const double _zeroDouble = 0.0;
const Color _transparent = Color(0x00000000);

/// Represents category.
class Category extends DataObject {
  factory Category.fromJson(MyJson row, [DataAbstract? data]) {
    return Category(
      id: row.getInt(SharedDomainStrings.domainString057, _unsetId),
      parentId: row.getInt(SharedDomainStrings.domainString102, _unsetId),
      name: row.getString(SharedDomainStrings.domainString088),
      description: row.getString(SharedDomainStrings.domainString046),
      color: row.getString(SharedDomainStrings.domainString038).trim(),
      type: CategoryTypeExtension.fromInt(row.getInt(SharedDomainStrings.domainString146)),
      budget: row.getDouble(SharedDomainStrings.domainString024),
      budgetBalance: row.getDouble(SharedDomainStrings.domainString019),
      frequency: row.getInt(SharedDomainStrings.domainString056),
      taxRefNum: row.getInt(SharedDomainStrings.domainString135),
      data: data,
    );
  }
  Category({
    required int id,
    required String name,
    required CategoryType type,
    int parentId = _unsetId,
    String description = '',
    String color = '',
    double budget = _zeroDouble,
    double budgetBalance = _zeroDouble,
    int frequency = _zeroInt,
    int taxRefNum = _zeroInt,
    this.data,
  }) {
    this.fieldId.value = id;
    this.fieldParentId.value = parentId;
    this.fieldName.value = name;
    this.fieldDescription.value = description;
    this.fieldColor.value = color;
    this.fieldType.value = type;
    this.fieldBudget.value.setAmount(budget);
    this.fieldBudgetBalance.value.setAmount(budgetBalance);
    this.fieldFrequency.value = frequency;
    this.fieldTaxRefNum.value = taxRefNum;
  }

  final DataAbstract? data;

  /// Budget
  /// 6|Budget|money|0||0
  FieldMoney fieldBudget = FieldMoney(
    serializeName: SharedDomainStrings.domainString024,
    getValueForDisplay: (DataInterface instance) => (instance as Category).fieldBudget.value,
    getValueForSerialization: (DataInterface instance) => (instance as Category).fieldBudget.value.asDouble(),
    setValue: (DataInterface instance, dynamic value) {
      (instance as Category).fieldBudget.value.setAmount(value);
    },
  );

  /// Budget Balance
  /// 7|Balance|money|0||0
  FieldMoney fieldBudgetBalance = FieldMoney(
    name: 'BudgetBalance',
    getValueForDisplay: (DataInterface instance) => (instance as Category).fieldBudgetBalance.value,
    getValueForSerialization: (DataInterface instance) => (instance as Category).fieldBudgetBalance.value.asDouble(),
  );

  /// Color
  /// 5|Color|nchar(10)|0||0
  Field<String> fieldColor = Field<String>(
    serializeName: SharedDomainStrings.domainString038,
    type: FieldType.widget,
    align: TextAlign.center,
    columnWidth: ColumnWidth.nano,
    defaultValue: '',
    getValueForDisplay: (DataInterface instance) => (instance as Category).fieldColor.value,
    getValueForSerialization: (DataInterface instance) => (instance as Category).fieldColor.value,
    setValue: (DataInterface instance, dynamic value) {
      (instance as Category).fieldColor.value = value as String;
    },
    sort: (DataInterface a, DataInterface b, bool ascending) => sortByValue(
      (a as Category).getColorOrAncestorsColor().computeLuminance(),
      (b as Category).getColorOrAncestorsColor().computeLuminance(),
      ascending,
    ),
  );

  /// Description
  /// 3|Description|nvarchar(255)|0||0
  FieldString fieldDescription = FieldString(
    columnWidth: ColumnWidth.large,
    serializeName: SharedDomainStrings.domainString046,
    getValueForDisplay: (DataInterface instance) => (instance as Category).fieldDescription.value,
    setValue: (DataInterface instance, dynamic value) =>
        (instance as Category).fieldDescription.value = value as String,
  );

  /// 8|Frequency|INT|0||0
  FieldInt fieldFrequency = FieldInt(
    serializeName: SharedDomainStrings.domainString056,
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForSerialization: (DataInterface instance) => (instance as Category).fieldFrequency.value,
  );

  /// Id
  /// 0|Id|INT|0||1
  FieldId fieldId = FieldId(
    getValueForSerialization: (DataInterface instance) => (instance as Category).uniqueId,
  );

  //-----------------------------------
  // These properties are not persisted

  /// Level
  FieldInt fieldLevel = FieldInt(
    align: TextAlign.center,
    name: 'Level',
    columnWidth: ColumnWidth.nano,
    type: FieldType.text,
    footer: FooterType.count,
    getValueForDisplay: (DataInterface instance) =>
        (countOccurrences((instance as Category).fieldName.value, ':') + _levelStep).toString(),
  );

  /// Name
  /// 2|Name|nvarchar(80)|1||0
  FieldString fieldName = FieldString(
    columnWidth: ColumnWidth.largest,
    serializeName: SharedDomainStrings.domainString088,
    type: FieldType.widget,
    getValueForDisplay: (DataInterface instance) => (instance as Category).fieldName.value,
    getValueForSerialization: (DataInterface instance) => (instance as Category).fieldName.value,
    setValue: (DataInterface instance, dynamic value) => (instance as Category).fieldName.value = value as String,
    sort: (DataInterface a, DataInterface b, bool ascending) => sortByString(
      (a as Category).fieldName.value,
      (b as Category).fieldName.value,
      ascending,
    ),
  );

  /// 1|ParentId|INT|0||0
  FieldInt fieldParentId = FieldInt(
    serializeName: SharedDomainStrings.domainString102,
    getValueForDisplay: (DataInterface instance) => (instance as Category).fieldParentId.value,
  );

  /// Running Balance
  FieldMoney fieldSum = FieldMoney(
    name: 'Sum',
    getValueForDisplay: (DataInterface instance) => (instance as Category).fieldSum.value,
  );

  /// Running Balance
  FieldMoney fieldSumRollup = FieldMoney(
    name: 'Sum~',
    getValueForDisplay: (DataInterface instance) => (instance as Category).fieldSumRollup.value,
  );

  /// 9|TaxRefNum|INT|0||0
  FieldInt fieldTaxRefNum = FieldInt(
    serializeName: SharedDomainStrings.domainString135,
    useAsDetailPanels: defaultCallbackValueFalse,
    getValueForSerialization: (DataInterface instance) => (instance as Category).fieldTaxRefNum.value,
  );

  /// Count
  FieldInt fieldTransactionCount = FieldInt(
    name: '#T',
    columnWidth: ColumnWidth.tiny,
    getValueForDisplay: (DataInterface instance) => (instance as Category).fieldTransactionCount.value,
  );

  /// Count
  FieldInt fieldTransactionCountRollup = FieldInt(
    name: '#T~',
    columnWidth: ColumnWidth.tiny,
    getValueForDisplay: (DataInterface instance) => (instance as Category).fieldTransactionCountRollup.value,
  );

  /// Type
  /// 4|Type|INT|1||0
  Field<CategoryType> fieldType = Field<CategoryType>(
    type: FieldType.text,
    align: TextAlign.center,
    serializeName: SharedDomainStrings.domainString146,
    defaultValue: CategoryType.none,
    footer: FooterType.count,
    getValueForDisplay: (DataInterface instance) => (instance as Category).getTypeAsText(),
    getValueForSerialization: (DataInterface instance) => (instance as Category).fieldType.value.index,
    setValue: (DataInterface instance, dynamic value) {
      (instance as Category).fieldType.value = CategoryTypeExtension.fromInt(value as int);
    },
  );

  // Fields for this instance
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  @override
  String getRepresentation() {
    return fieldName.value;
  }

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(int value) => fieldId.value = value;

  static final Fields<Category> _fields = Fields<Category>();
  static final Fields<Category> _fieldsForColumns = Fields<Category>();
  static final List<FieldBlueprint<Category>> _fieldBlueprints = <FieldBlueprint<Category>>[
    FieldBlueprint<Category>(selector: (Category tmp) => tmp.fieldId),
    FieldBlueprint<Category>(selector: (Category tmp) => tmp.fieldParentId),
    FieldBlueprint<Category>(selector: (Category tmp) => tmp.fieldLevel, includeInColumnView: true),
    FieldBlueprint<Category>(selector: (Category tmp) => tmp.fieldColor, includeInColumnView: true),
    FieldBlueprint<Category>(selector: (Category tmp) => tmp.fieldName, includeInColumnView: true),
    FieldBlueprint<Category>(
      selector: (Category tmp) => tmp.fieldDescription,
      includeInColumnView: true,
    ),
    FieldBlueprint<Category>(selector: (Category tmp) => tmp.fieldType, includeInColumnView: true),
    FieldBlueprint<Category>(selector: (Category tmp) => tmp.fieldBudget, includeInColumnView: true),
    FieldBlueprint<Category>(
      selector: (Category tmp) => tmp.fieldBudgetBalance,
      includeInColumnView: true,
    ),
    FieldBlueprint<Category>(selector: (Category tmp) => tmp.fieldFrequency),
    FieldBlueprint<Category>(selector: (Category tmp) => tmp.fieldTaxRefNum),
    FieldBlueprint<Category>(
      selector: (Category tmp) => tmp.fieldTransactionCount,
      includeInColumnView: true,
    ),
    FieldBlueprint<Category>(selector: (Category tmp) => tmp.fieldSum, includeInColumnView: true),
    FieldBlueprint<Category>(
      selector: (Category tmp) => tmp.fieldTransactionCountRollup,
      includeInColumnView: true,
    ),
    FieldBlueprint<Category>(selector: (Category tmp) => tmp.fieldSumRollup, includeInColumnView: true),
  ];

  /// Returns the field definitions for Category entities.
  static Fields<Category> get fields => ensureCachedFieldDefinitionsFromBlueprints<Category>(
    cache: _fields,
    instanceFactory: () => Category.fromJson(<String, dynamic>{}),
    blueprints: _fieldBlueprints,
    forColumnView: false,
  );

  /// Returns the field definitions for Category column view.
  static Fields<Category> get fieldsForColumnView => ensureCachedFieldDefinitionsFromBlueprints<Category>(
    cache: _fieldsForColumns,
    instanceFactory: () => Category.fromJson(<String, dynamic>{}),
    blueprints: _fieldBlueprints,
    forColumnView: true,
  );

  /// Populates [list] with all ancestor categories recursively.
  void getAncestors(List<Category> list) {
    if (parentCategory != null) {
      list.add(parentCategory!);
      parentCategory!.getAncestors(list);
    }
  }

  /// Returns the category color and hierarchy level.
  Pair<Color, int> getColorAndLevel(int level) {
    if (this.fieldColor.value.isNotEmpty) {
      return Pair<Color, int>(getColorFromString(this.fieldColor.value), level);
    }

    if (parentCategory != null) {
      return parentCategory!.getColorAndLevel(level + _levelStep);
    }

    // reach the top
    return Pair<Color, int>(_transparent, _zeroInt);
  }

  /// Returns this category's color or inherits from ancestors.
  Color getColorOrAncestorsColor() {
    final Pair<Color, int> pair = getColorAndLevel(_zeroInt);
    return pair.first;
  }

  /// Populates [list] with all descendant categories recursively.
  void getDescendants(List<Category> list) {
    final Iterable<Category> allCategories = data?.getCategories(includeDeleted: true).cast<Category>() ?? <Category>[];
    for (final Category category in allCategories) {
      if (category.fieldParentId.value == this.uniqueId) {
        list.add(category);
        category.getDescendants(list);
      }
    }
  }

  /// Returns the category name; empty string if null.
  static String getName(Category? instance) {
    return instance == null ? '' : instance.fieldName.value;
  }

  /// Returns the category type as a display string.
  String getTypeAsText() {
    return fieldType.value.asString();
  }

  /// True if this category is an expense type.
  bool get isExpense => fieldType.value == CategoryType.expense || fieldType.value == CategoryType.recurringExpense;

  /// True if this category is an income type.
  bool get isIncome => fieldType.value == CategoryType.income || fieldType.value == CategoryType.investment;

  /// True if this category is a recurring expense.
  bool get isRecurring => fieldType.value == CategoryType.recurringExpense;

  ///
  /// The last part of the full name of the Category without the ancestor names
  ///
  String get leafName {
    return name.split(':').last;
  }

  ///
  /// The full name of the Category
  ///
  String get name {
    return fieldName.value;
  }

  /// Returns the parent category, if any.
  Category? get parentCategory {
    return data?.getCategory(this.fieldParentId.value) as Category?;
  }

  /// Updates the name based on the parent category by appending the leaf name of the category to its current name.
  /// If the parent category is not null, it extracts the leaf name from the current name, and then rebuilds the new full name
  /// by combining the parent's full name with the leaf name.
  void updateNameBaseOnParent() {
    if (parentCategory == null) {
      // No update needed since there is not parent for this category
    } else {
      // rebuild the new full name parent full name + this leaf name
      stashValueBeforeEditing();
      fieldName.value = '${parentCategory!.fieldName.value}:$leafName';
      data!.notifyMutationChanged(
        mutation: MutationType.changed,
        moneyObject: this,
        recalculateBalances: false,
      );
    }
  }
}
