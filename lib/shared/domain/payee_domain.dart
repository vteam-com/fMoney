import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/field_definition_cache.dart';
import 'package:money/widgets/list/list_item_card.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const int _singleCategoryCount = 1;
const int _doubleCategoryCount = 2;

/*
  SQLite table definition

  0|Id|INT|0||1
  1|Name|nvarchar(255)|1||0
 */
/// Represents payee.
class Payee extends DataObject {
  Payee();

  factory Payee.fromJson(final MyJson _ /* json */) {
    return Payee();
  }

  Set<String> categories = <String>{};
  FieldString fieldCategoriesAsText = FieldString(
    name: SharedDomainStrings.domainString028,
    getValueForDisplay: (final DataInterface instance) => (instance as Payee).getCategoriesAsString(),
  );

  FieldInt fieldCount = FieldInt(
    name: SharedDomainStrings.domainString143,
    columnWidth: ColumnWidth.small,
    getValueForDisplay: (final DataInterface instance) => (instance as Payee).fieldCount.value,
  );

  // 0 - ID
  FieldId fieldId = FieldId(
    getValueForSerialization: (final DataInterface instance) => (instance as Payee).uniqueId,
  );

  // 1
  FieldString fieldName = FieldString(
    name: SharedDomainStrings.domainString088,
    serializeName: SharedDomainStrings.domainString088,
    getValueForDisplay: (final DataInterface instance) => (instance as Payee).fieldName.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Payee).fieldName.value,
    setValue: (final DataInterface instance, dynamic value) => (instance as Payee).fieldName.value = value as String,
  );

  FieldMoney fieldSum = FieldMoney(
    name: 'Sum',
    getValueForDisplay: (final DataInterface instance) => (instance as Payee).fieldSum.value,
  );

  @override
  Widget buildFieldsAsWidgetForSmallScreen() {
    return MyListItemAsCard(
      leftTopAsString: fieldName.value,
      rightTopAsWidget: WidgetFromData(
        amountModel: fieldSum.value,
        size: DataWidgetSize.title,
      ),
      rightBottomAsString: getAmountAsShorthandText(fieldCount.value),
    );
  }

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
  set uniqueId(final int value) => fieldId.value = value;

  static final Fields<Payee> _fields = Fields<Payee>();
  static final Fields<Payee> _fieldsForColumns = Fields<Payee>();
  static final List<FieldBlueprint<Payee>> _fieldBlueprints = <FieldBlueprint<Payee>>[
    FieldBlueprint<Payee>(selector: (Payee tmp) => tmp.fieldId),
    FieldBlueprint<Payee>(selector: (Payee tmp) => tmp.fieldName, includeInColumnView: true),
    FieldBlueprint<Payee>(
      selector: (Payee tmp) => tmp.fieldCategoriesAsText,
      includeInColumnView: true,
    ),
    FieldBlueprint<Payee>(selector: (Payee tmp) => tmp.fieldCount, includeInColumnView: true),
    FieldBlueprint<Payee>(selector: (Payee tmp) => tmp.fieldSum, includeInColumnView: true),
  ];

  /// Returns the field definitions for Payee entities.
  static Fields<Payee> get fields => ensureCachedFieldDefinitionsFromBlueprints<Payee>(
    cache: _fields,
    instanceFactory: () => Payee.fromJson(<String, dynamic>{}),
    blueprints: _fieldBlueprints,
    forColumnView: false,
  );

  /// Returns the field definitions for Payee column view.
  static Fields<Payee> get fieldsForColumnView => ensureCachedFieldDefinitionsFromBlueprints<Payee>(
    cache: _fieldsForColumns,
    instanceFactory: () => Payee.fromJson(<String, dynamic>{}),
    blueprints: _fieldBlueprints,
    forColumnView: true,
  );

  /// Returns a string representation of the categories associated with the payee.
  /// If there are no categories, an empty string is returned.
  /// If there is one category, that category is returned.
  /// If there are two categories, they are joined with a semicolon and space.
  /// If there are more than two categories, the number of categories is returned as a string.
  String getCategoriesAsString() {
    if (categories.isEmpty) {
      return '';
    }

    if (categories.length == _singleCategoryCount) {
      return categories.first;
    }
    if (categories.length == _doubleCategoryCount) {
      return categories.join('; ');
    }
    return '${getIntAsText(categories.length)}${SharedDomainStrings.domainString002}';
  }

  /// Returns the name of the [Payee] object, or an empty string if the [Payee] is null.
  static String getName(final Payee? payee) {
    return payee == null ? '' : payee.fieldName.value;
  }
}
