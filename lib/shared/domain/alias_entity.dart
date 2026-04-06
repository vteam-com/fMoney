// ignore_for_file: unnecessary_this

import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/data/models/field_type_enum.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/shared/domain/field_definition_cache_helper.dart';
import 'package:money/widgets/list/list_item_card.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';

/// Represents alias.
class Alias extends DataObject {
  /// Constructor for backwards compatibility with static methods
  Alias._legacy({
    required int id,
    required String pattern,
    required int flags,
    required int payeeId,
  }) : data = null {
    this.fieldId.value = id;
    this.fieldPattern.value = pattern;
    this.fieldFlags.value = flags;
    this.fieldPayeeId.value = payeeId;
  }

  /// Factory method for static fields
  factory Alias._fromJsonStatic(final MyJson row) {
    return Alias._legacy(
      id: row.getInt(SharedDomainStrings.domainString057, -1),
      pattern: row.getString(SharedDomainStrings.domainString104),
      flags: row.getInt(SharedDomainStrings.domainString055),
      payeeId: row.getInt(SharedDomainStrings.domainString105, -1),
    );
  }

  /// Constructor from a SQLite row
  factory Alias.fromJson(final MyJson row, final DataAbstract data) {
    return Alias(
      id: row.getInt(SharedDomainStrings.domainString057, -1),
      pattern: row.getString(SharedDomainStrings.domainString104),
      flags: row.getInt(SharedDomainStrings.domainString055),
      payeeId: row.getInt(SharedDomainStrings.domainString105, -1),
      data: data,
    );
  }
  Alias({
    required final int id,
    required final String pattern,
    required final int flags,
    required final int payeeId,
    required this.data,
  }) {
    this.fieldId.value = id;
    this.fieldPattern.value = pattern;
    this.fieldFlags.value = flags;
    this.fieldPayeeId.value = payeeId;
  }

  final DataAbstract? data;

  /// SQL [2] SharedDomainStrings.domainString055 INT
  FieldInt fieldFlags = FieldInt(
    type: FieldType.text,
    align: TextAlign.center,
    name: SharedDomainStrings.domainString055,
    serializeName: SharedDomainStrings.domainString055,
    defaultValue: 0,
    footer: FooterType.count,
    getValueForDisplay: (final DataInterface instance) => getAliasTypeAsString((instance as Alias).type),
    getValueForSerialization: (final DataInterface instance) => (instance as Alias).fieldFlags.value,
  );

  /// ID
  /// 0    Id       INT            0                 1
  FieldId fieldId = FieldId(
    getValueForSerialization: (final DataInterface instance) => (instance as Alias).uniqueId,
  );

  /// Pattern
  /// SQL[1] "Pattern"  nvarchar(255)
  FieldString fieldPattern = FieldString(
    type: FieldType.text,
    name: SharedDomainStrings.domainString104,
    serializeName: SharedDomainStrings.domainString104,
    getValueForDisplay: (final DataInterface instance) => (instance as Alias).fieldPattern.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Alias).fieldPattern.value,
    setValue: (final DataInterface instance, dynamic value) => (instance as Alias).fieldPattern.value = value as String,
  );

  /// Payee
  /// 3 Payee INT 1 0
  FieldInt fieldPayeeId = FieldInt(
    type: FieldType.text,
    footer: FooterType.count,
    name: SharedDomainStrings.domainString105,
    serializeName: SharedDomainStrings.domainString105,
    defaultValue: 0,
    getValueForDisplay: (final DataInterface instance) =>
        (instance as Alias).data!.getPayeeName(instance.fieldPayeeId.value),
    getValueForSerialization: (final DataInterface instance) => (instance as Alias).fieldPayeeId.value,
  );

  RegExp? regex;

  @override
  Widget buildFieldsAsWidgetForSmallScreen() {
    return MyListItemAsCard(
      leftTopAsString: this.data!.getPayeeName(this.fieldPayeeId.value),
      leftBottomAsString: fieldPattern.value,
      rightBottomAsString: '${getAliasTypeAsString(type)}${SharedDomainStrings.domainString158}',
    );
  }

  // Fields for this instance
  @override
  FieldDefinitions get fieldDefinitions => fields.definitions;

  @override
  String getRepresentation() {
    return fieldPattern.value;
  }

  @override
  int get uniqueId => fieldId.value;

  @override
  set uniqueId(final int value) => fieldId.value = value;

  static final Fields<Alias> _fields = Fields<Alias>();
  static final Fields<Alias> _fieldsForColumns = Fields<Alias>();
  static final List<FieldBlueprint<Alias>> _fieldBlueprints = <FieldBlueprint<Alias>>[
    FieldBlueprint<Alias>(selector: (Alias tmp) => tmp.fieldId),
    FieldBlueprint<Alias>(selector: (Alias tmp) => tmp.fieldPattern, includeInColumnView: true),
    FieldBlueprint<Alias>(selector: (Alias tmp) => tmp.fieldFlags, includeInColumnView: true),
    FieldBlueprint<Alias>(selector: (Alias tmp) => tmp.fieldPayeeId, includeInColumnView: true),
  ];

  /// Returns the field definitions for Alias entities.
  static Fields<Alias> get fields => ensureCachedFieldDefinitionsFromBlueprints<Alias>(
    cache: _fields,
    instanceFactory: () => Alias._fromJsonStatic(<String, dynamic>{}),
    blueprints: _fieldBlueprints,
    forColumnView: false,
  );

  /// Returns the field definitions for Alias column view.
  static Fields<Alias> get fieldsForColumnView => ensureCachedFieldDefinitionsFromBlueprints<Alias>(
    cache: _fieldsForColumns,
    instanceFactory: () => Alias._fromJsonStatic(<String, dynamic>{}),
    blueprints: _fieldBlueprints,
    forColumnView: true,
  );

  /// Checks if the given [text] matches this alias (regex or exact).
  bool isMatch(final String text) {
    if (type == AliasType.regex) {
      // just in time creation of RegEx property
      regex ??= RegExp(fieldPattern.value);
      final Match? matched = regex?.firstMatch(text);
      if (matched != null) {
        return true;
      }
    } else {
      if (stringCompareIgnoreCasing(fieldPattern.value, text) == 0) {
        return true;
      }
    }
    return false;
  }

  /// Returns the alias type based on flags.
  AliasType get type {
    return fieldFlags.value == 0 ? AliasType.none : AliasType.regex;
  }
}
