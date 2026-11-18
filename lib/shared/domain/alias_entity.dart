// ignore_for_file: unnecessary_this

import 'dart:ui' show TextAlign;

import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/data/models/data_interface.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/data/models/field_type_enum.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/field_definition_cache_helper.dart';
import 'package:money/shared/domain/payee_operations_interface.dart';

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
  factory Alias._fromJsonStatic(MyJson row) {
    return Alias._legacy(
      id: row.getInt(SharedDomainStrings.domainString057, -1),
      pattern: row.getString(SharedDomainStrings.domainString104),
      flags: row.getInt(SharedDomainStrings.domainString055),
      payeeId: row.getInt(SharedDomainStrings.domainString105, -1),
    );
  }

  /// Constructor from a SQLite row
  factory Alias.fromJson(MyJson row, PayeeOperations data) {
    return Alias(
      id: row.getInt(SharedDomainStrings.domainString057, -1),
      pattern: row.getString(SharedDomainStrings.domainString104),
      flags: row.getInt(SharedDomainStrings.domainString055),
      payeeId: row.getInt(SharedDomainStrings.domainString105, -1),
      data: data,
    );
  }
  Alias({
    required int id,
    required String pattern,
    required int flags,
    required int payeeId,
    required this.data,
  }) {
    this.fieldId.value = id;
    this.fieldPattern.value = pattern;
    this.fieldFlags.value = flags;
    this.fieldPayeeId.value = payeeId;
  }

  final PayeeOperations? data;

  /// SQL [2] SharedDomainStrings.domainString055 INT
  FieldInt fieldFlags = FieldInt(
    type: FieldType.text,
    align: TextAlign.center,
    serializeName: SharedDomainStrings.domainString055,
    defaultValue: 0,
    footer: FooterType.count,
    getValueForDisplay: (DataInterface instance) => getAliasTypeAsString((instance as Alias).type),
    getValueForSerialization: (DataInterface instance) => (instance as Alias).fieldFlags.value,
    setValue: (DataInterface instance, dynamic value) => (instance as Alias).fieldFlags.value = value as int,
  );

  /// ID
  /// 0    Id       INT            0                 1
  FieldId fieldId = FieldId(
    getValueForSerialization: (DataInterface instance) => (instance as Alias).uniqueId,
  );

  /// Pattern
  /// SQL[1] "Pattern"  nvarchar(255)
  FieldString fieldPattern = FieldString(
    type: FieldType.text,
    serializeName: SharedDomainStrings.domainString104,
    getValueForDisplay: (DataInterface instance) => (instance as Alias).fieldPattern.value,
    setValue: (DataInterface instance, dynamic value) => (instance as Alias).fieldPattern.value = value as String,
  );

  /// Payee
  /// 3 Payee INT 1 0
  FieldInt fieldPayeeId = FieldInt(
    type: FieldType.text,
    footer: FooterType.count,
    serializeName: SharedDomainStrings.domainString105,
    defaultValue: 0,
    getValueForDisplay: (DataInterface instance) => (instance as Alias).payeeName,
    getValueForSerialization: (DataInterface instance) => (instance as Alias).fieldPayeeId.value,
    setValue: (DataInterface instance, dynamic value) => (instance as Alias).fieldPayeeId.value = value as int,
    // By payee name, then pattern, so each payee's patterns stay together.
    sort: (DataInterface a, DataInterface b, bool ascending) {
      final int byPayee = sortByString((a as Alias).payeeName, (b as Alias).payeeName, ascending);
      return byPayee != 0 ? byPayee : sortByString(a.fieldPattern.value, b.fieldPattern.value, true);
    },
  );

  /// How many aliases map to this alias's payee; computed by [Aliases.updatePatternCounts], not stored.
  FieldInt fieldPatternCount = FieldInt(
    name: SharedDomainStrings.domainString164,
    columnWidth: ColumnWidth.small,
    getValueForDisplay: (DataInterface instance) => (instance as Alias).fieldPatternCount.value,
  );

  /// Name of the payee this alias maps to.
  String get payeeName => data!.getPayeeName(fieldPayeeId.value);

  /// Compiled regex for [_regexPattern]; null when that pattern is not a valid regex.
  RegExp? _regex;

  /// The pattern [_regex] was compiled from, so an edited pattern gets recompiled.
  String? _regexPattern;

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
  set uniqueId(int value) => fieldId.value = value;

  static final Fields<Alias> _fields = Fields<Alias>();
  static final Fields<Alias> _fieldsForColumns = Fields<Alias>();
  static final List<FieldBlueprint<Alias>> _fieldBlueprints = <FieldBlueprint<Alias>>[
    FieldBlueprint<Alias>(selector: (Alias tmp) => tmp.fieldId),
    FieldBlueprint<Alias>(selector: (Alias tmp) => tmp.fieldPattern),
    FieldBlueprint<Alias>(selector: (Alias tmp) => tmp.fieldFlags),
    FieldBlueprint<Alias>(selector: (Alias tmp) => tmp.fieldPayeeId),
  ];

  /// Columns of the Aliases view: the payee first, so its patterns read together under it.
  static final List<FieldBlueprint<Alias>> _columnBlueprints = <FieldBlueprint<Alias>>[
    FieldBlueprint<Alias>(selector: (Alias tmp) => tmp.fieldPayeeId, includeInColumnView: true),
    FieldBlueprint<Alias>(selector: (Alias tmp) => tmp.fieldPattern, includeInColumnView: true),
    FieldBlueprint<Alias>(selector: (Alias tmp) => tmp.fieldFlags, includeInColumnView: true),
    FieldBlueprint<Alias>(selector: (Alias tmp) => tmp.fieldPatternCount, includeInColumnView: true),
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
    blueprints: _columnBlueprints,
    forColumnView: true,
  );

  /// Checks if the given [text] matches this alias, the way MyMoney.Net does:
  /// a regex must cover the whole text, a plain pattern must equal it ignoring case.
  bool isMatch(String text) {
    if (text.trim().isEmpty) {
      return false;
    }
    if (type == AliasType.regex) {
      final RegExp? regex = _compiledRegex();
      final RegExpMatch? match = regex?.firstMatch(text);
      return match != null && match.start == 0 && match.end == text.length;
    }
    return stringCompareIgnoreCasing(fieldPattern.value, text) == 0;
  }

  /// Returns the regex for the current pattern, recompiling it when the pattern was edited.
  RegExp? _compiledRegex() {
    final String pattern = fieldPattern.value;
    if (_regexPattern != pattern) {
      _regexPattern = pattern;
      _regex = tryParseAliasRegex(pattern);
    }
    return _regex;
  }

  /// Returns the alias type based on flags.
  AliasType get type {
    return fieldFlags.value == 0 ? AliasType.none : AliasType.regex;
  }
}

/// MyMoney.Net inline option that makes a whole pattern case-insensitive; Dart's RegExp rejects it.
const String _caseInsensitivePrefix = '(?i)';

/// Compiles an alias [pattern], honoring a leading `(?i)`; returns null when the pattern is not a valid regex.
RegExp? tryParseAliasRegex(String pattern) {
  final bool ignoreCase = pattern.startsWith(_caseInsensitivePrefix);
  final String source = ignoreCase ? pattern.substring(_caseInsensitivePrefix.length) : pattern;
  try {
    return RegExp(source, caseSensitive: !ignoreCase);
  } on FormatException {
    return null;
  }
}
