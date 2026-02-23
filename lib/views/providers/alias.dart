// ignore_for_file: unnecessary_this

import 'package:money/data/models/alias_types.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/views/providers/data_abstract.dart';
import 'package:money/views/providers/field_definition_cache.dart';
import 'package:money/widgets/adaptive_list/list_item_card.dart';
import 'package:money/widgets/widgets_domain/data_interface.dart';
import 'package:money/widgets/widgets_domain/data_object.dart';
import 'package:money/widgets/widgets_domain/field.dart';
import 'package:money/widgets/widgets_domain/field_type.dart';

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
      id: row.getInt('Id', -1),
      pattern: row.getString('Pattern'),
      flags: row.getInt('Flags'),
      payeeId: row.getInt('Payee', -1),
    );
  }

  /// Constructor from a SQLite row
  factory Alias.fromJson(final MyJson row, final DataAbstract data) {
    return Alias(
      id: row.getInt('Id', -1),
      pattern: row.getString('Pattern'),
      flags: row.getInt('Flags'),
      payeeId: row.getInt('Payee', -1),
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

  /// SQL [2] 'Flags' INT
  FieldInt fieldFlags = FieldInt(
    type: FieldType.text,
    align: TextAlign.center,
    name: 'Flags',
    serializeName: 'Flags',
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
    name: 'Pattern',
    serializeName: 'Pattern',
    getValueForDisplay: (final DataInterface instance) => (instance as Alias).fieldPattern.value,
    getValueForSerialization: (final DataInterface instance) => (instance as Alias).fieldPattern.value,
    setValue: (final DataInterface instance, dynamic value) => (instance as Alias).fieldPattern.value = value as String,
  );

  /// Payee
  /// 3 Payee INT 1 0
  FieldInt fieldPayeeId = FieldInt(
    type: FieldType.text,
    footer: FooterType.count,
    name: 'Payee',
    serializeName: 'Payee',
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
      rightBottomAsString: '${getAliasTypeAsString(type)}\n',
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

  /// Builds [Alias] field definitions for cache initialization.
  static FieldDefinitions _buildFieldDefinitions(final Alias tmp) => <Field<dynamic>>[
    tmp.fieldId,
    tmp.fieldPattern,
    tmp.fieldFlags,
    tmp.fieldPayeeId,
  ];

  /// Returns the field definitions for Alias entities.
  static Fields<Alias> get fields => ensureCachedFieldDefinitions<Alias>(
    cache: _fields,
    instanceFactory: () => Alias._fromJsonStatic(<String, dynamic>{}),
    definitionsBuilder: _buildFieldDefinitions,
  );

  /// Returns the field definitions for Alias column view.
  static Fields<Alias> get fieldsForColumnView {
    if (_fieldsForColumns.isEmpty) {
      // used for the first time
      final Alias tmp = Alias._fromJsonStatic(<String, dynamic>{});
      _fieldsForColumns.setDefinitions(<Field<dynamic>>[
        tmp.fieldPattern,
        tmp.fieldFlags,
        tmp.fieldPayeeId,
      ]);
    }

    // return the cached singleton
    return _fieldsForColumns;
  }

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
