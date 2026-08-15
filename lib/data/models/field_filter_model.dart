// ignore_for_file: unnecessary_this

import 'dart:convert';

import 'package:money/data/models/ranges_model.dart';

const int _minimumDateRangeTokens = 2;

/// Represents a filter associated with a specific field name.
/// It contains a list of string values and an optional date range filter.
class FieldFilter {
  /// Constructs a new instance of the `FieldFilter` class.
  ///
  /// The [fieldName] is required and represents the name of the field.
  /// The [strings] list contains the values that the field must match when filtering.
  /// The optional [byDateRange] indicates whether the filter is based on a date range.
  FieldFilter({
    required this.fieldName,
    required List<String> strings,
    this.byDateRange = false,
  }) : strings = List<String>.from(strings); // Ensures type safety

  /// Creates a `FieldFilter` instance from a JSON map.
  factory FieldFilter.fromJson(Map<String, dynamic> json) {
    return FieldFilter(
      fieldName: json['fieldName'] as String? ?? '',
      strings: (json['strings'] as List<dynamic>?)?.map<String>((dynamic e) => e.toString()).toList() ?? <String>[],
      byDateRange: json['byDateRange'] as bool? ?? false,
    );
  }

  /// Converts the `FieldFilter` instance to a JSON map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'fieldName': fieldName,
      'strings': strings, // Ensures it's a `List<String>`
      'byDateRange': byDateRange,
    };
  }

  /// Indicates whether the filter is based on a date range.
  final bool byDateRange;

  /// The name of the field being filtered.
  final String fieldName;

  /// The list of string values associated with the field.
  final List<String> strings;

  /// Returns a string representation of the `FieldFilter` instance in JSON format.
  @override
  String toString() {
    return jsonEncode(toJson());
  }

  /// Returns a `DateRange` representation if the filter is based on a date range.
  ///
  /// Ensures that there are at least two string values before calling `DateRange.fromText`.
  DateRange? get asDateRange {
    if (byDateRange && strings.length >= _minimumDateRangeTokens) {
      return DateRange.fromText(strings.first, strings.last);
    }
    return null;
  }

  /// Checks if the given [value] is contained in the [strings] list, ignoring case.
  ///
  /// Returns `true` if a string in the [strings] list matches the [value], ignoring case.
  bool contains(dynamic value) {
    if (value is! String) {
      return false;
    }
    return strings.any(
      (String text) => stringCompareIgnoreCasing(text, value) == 0,
    );
  }
}
