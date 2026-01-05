import 'package:money/helpers/json_helper.dart';
import 'package:money/widgets/field_filter.dart';

/// Group a lists of filters
class FieldFilters {
  /// Constructs a `FieldFilters` instance from a JSON string.
  ///
  /// The JSON string is expected to be a valid JSON representation of a `FieldFilters` object.
  /// This method decodes the JSON string and uses `fromJson` to create a new `FieldFilters` instance.
  factory FieldFilters.fromJsonString(final String jsonString) {
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
  factory FieldFilters.fromJson(final Map<String, dynamic> json) {
    final List<dynamic> filters = json['filters'] as List<dynamic>;
    final List<FieldFilter> fieldFilters = filters
        .map(
          (dynamic filter) => FieldFilter.fromJson(filter as Map<String, dynamic>),
        )
        .toList();
    return FieldFilters(fieldFilters);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'filters': list.map((FieldFilter filter) => filter.toJson()).toList(),
    };
  }

  List<FieldFilter> list = <FieldFilter>[];

  void add(final FieldFilter ff) {
    list.add(ff);
  }

  void clear() {
    list.clear();
  }

  bool get isEmpty => list.isEmpty;

  bool get isNotEmpty => !isEmpty;

  int get length => list.length;

  @override
  String toString() {
    return toJsonString();
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}
