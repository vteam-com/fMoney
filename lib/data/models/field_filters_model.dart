import 'package:collection/collection.dart';
import 'package:money/data/models/field_filter_model.dart';
import 'package:money/helpers/json_helper.dart';

/// Group a lists of filters
class FieldFilters {
  /// Constructs a `FieldFilters` instance from a JSON string.
  ///
  /// The JSON string is expected to be a valid JSON representation of a `FieldFilters` object.
  /// This method decodes the JSON string and uses `fromJson` to create a new `FieldFilters` instance.
  factory FieldFilters.fromJsonString(String jsonString) {
    if (jsonString.isEmpty) {
      return FieldFilters();
    }
    final Map<String, dynamic> json = jsonDecode(jsonString) as Map<String, dynamic>;
    return FieldFilters.fromJson(json);
  }
  FieldFilters([List<FieldFilter>? inputList]) {
    this.list = inputList ?? <FieldFilter>[];
  }

  /// Constructs a `FieldFilters` instance from a JSON map.
  ///
  /// The JSON map is expected to have a `'filters'` key, which should be a list of JSON
  /// objects representing `FieldFilter` instances. This method creates a new `FieldFilters`
  /// instance and populates its `list` with `FieldFilter` instances constructed from the
  /// JSON objects.
  factory FieldFilters.fromJson(Map<String, dynamic> json) {
    final List<dynamic> filters = json['filters'] as List<dynamic>;
    final List<FieldFilter> fieldFilters = filters
        .map(
          (dynamic filter) => FieldFilter.fromJson(filter as Map<String, dynamic>),
        )
        .toList();
    return FieldFilters(fieldFilters);
  }

  /// Serializes this filter group to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'filters': list.map((FieldFilter filter) => filter.toJson()).toList(),
    };
  }

  List<FieldFilter> list = <FieldFilter>[];

  /// Adds a filter to this group.
  void add(FieldFilter ff) {
    list.add(ff);
  }

  /// Removes all filters from this group.
  void clear() {
    list.clear();
  }

  /// Removes the filters on column [fieldName], keeping the other columns' filters.
  void removeByFieldName(String fieldName) {
    list.removeWhere((FieldFilter filter) => filter.fieldName == fieldName);
  }

  /// Returns true if there are no filters.
  bool get isEmpty => list.isEmpty;

  /// Returns true if there is at least one filter.
  bool get isNotEmpty => !isEmpty;

  /// Returns true when [value] of column [fieldName] passes that column's filter, or the column has none.
  bool isValueSelected(String fieldName, String value) {
    final FieldFilter? filter = list.firstWhereOrNull((FieldFilter filter) => filter.fieldName == fieldName);
    if (filter == null) {
      return true;
    }
    if (filter.byDateRange) {
      return filter.asDateRange?.isBetweenEqual(DateTime.tryParse(value)) ?? true;
    }
    return filter.contains(value);
  }

  /// Returns the number of filters in this group.
  int get length => list.length;

  @override
  String toString() {
    return toJsonString();
  }

  /// Serializes this filter group to a JSON string.
  String toJsonString() {
    return jsonEncode(toJson());
  }
}
