import 'dart:convert';

import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/string_helper.dart';

export 'dart:convert';

/// Compares two JSON objects and generates a new JSON object containing only the common key-value pairs.
///
/// This function iterates over the keys in the first JSON object (`json1`) and checks if the key exists in the second JSON object (`json2`) with the same value. If so, the key-value pair is added to the `commonJson` object, which is then returned.
///
/// This function can be useful for finding the common data between two JSON objects, which can be helpful in scenarios like data synchronization or merging.
///
/// @param json1 The first JSON object to compare.
/// @param json2 The second JSON object to compare.
/// @return A new JSON object containing only the common key-value pairs between `json1` and `json2`.
MyJson compareAndGenerateCommonJson(MyJson json1, MyJson json2) {
  final MyJson commonJson = <String, dynamic>{};

  // Iterate over keys in json1
  json1.forEach((String key, dynamic value) {
    // Check if the key exists in json2 and has the same value
    if (json2.containsKey(key) && json2[key] == value) {
      // Add the key-value pair to the commonJson
      commonJson[key] = value;
    }
    // commonJson[key] = '';
  });

  return commonJson;
}

/// Encodes a dynamic value by wrapping string types in single quotes and escaping the string content.
///
/// If the input `value` is a [String], this function will return the value wrapped in single quotes with the string content escaped using [escapeString]. Otherwise, it will return the string representation of the value using [toString()].
///
/// This function is useful for safely encoding dynamic values as part of a larger string, such as when building SQL queries or other text-based formats.
///
/// @param value The dynamic value to encode.
/// @return The encoded value as a [String].
String encodeValueWrapStringTypes(dynamic value) {
  if (value is String) {
    return "'${escapeString(value)}'";
  } else {
    return value.toString();
  }
}

/// Diff between to JSon object
/// Generates a new JSON object that represents the differences between two JSON objects.
///
/// This function takes two JSON objects, `before` and `after`, and compares their key-value pairs. It creates a new JSON object `diff` that contains only the keys where the values differ between the two input objects. For each differing key, the `diff` object contains a map with the `'before'` and `'after'` values.
///
/// This function can be useful for tracking changes between two versions of a JSON data structure, such as when synchronizing data or generating update diffs.
///
/// @param before The JSON object representing the original or previous state.
/// @param after The JSON object representing the updated or current state.
/// @return A new JSON object containing the differences between `before` and `after`.
MyJson myJsonDiff({required MyJson before, required MyJson after}) {
  final MyJson diff = MyJson();

  after.forEach((String key, dynamic valueAfter) {
    final dynamic valueBefore = before[key];
    if (valueBefore != valueAfter) {
      diff[key] = <String, dynamic>{'before': valueBefore, 'after': valueAfter};
    }
  });
  return diff;
}

/// Creates a new [MyJson] object from parallel lists of keys and values.
///
/// This function takes two lists, one containing keys and one containing values, and constructs a new [MyJson] object where each key is associated with the corresponding value.
///
/// @param keys The list of keys to use for the new [MyJson] object.
/// @param values The list of values to associate with the keys.
/// @return A new [MyJson] object constructed from the provided keys and values.
MyJson myJsonFromKeyValuePairs(List<String> keys, List<String> values) {
  final MyJson object = <String, dynamic>{};
  for (int i = 0; i < keys.length; i++) {
    object[keys[i]] = values[i];
  }
  return object;
}

/// A type alias for a Map with String keys and dynamic values, representing a JSON-like object.
typedef MyJson = Map<String, dynamic>;

/// helpers for retrieving value as types
extension MyJsonExtensions on MyJson {
  /// Retrieves a boolean value from the JSON object for the given key.
  ///
  /// If the value for the specified key is `null` or cannot be parsed as a boolean, the provided [defaultIfNotFound] value is returned.
  ///
  /// @param key The key to retrieve the boolean value for.
  /// @param defaultIfNotFound The default value to return if the key is not found or the value cannot be parsed as a boolean. Defaults to `false`.
  /// @return The boolean value associated with the key, or the default value if the key is not found or the value is not a boolean.
  bool getBool(String key, [bool defaultIfNotFound = false]) {
    final dynamic value = this[key];
    if (value == null) {
      return defaultIfNotFound;
    }
    try {
      if (value is bool) {
        return value;
      }

      return value as bool;
    } catch (_) {
      return defaultIfNotFound;
    }
  }

  /// Expected input format to be
  /// '1999-12-25T00:00:00.000'
  /// or
  /// '1999-12-25'
  DateTime? getDate(String key, {DateTime? defaultIfNotFound}) {
    final dynamic value = this[key];

    if (value == null || value.toString().isEmpty) {
      return defaultIfNotFound;
    }

    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return defaultIfNotFound;
    }
  }

  /// Retrieves a double value from the JSON object for the given key.
  ///
  /// If the value for the specified key is `null`, the provided [defaultIfNotFound] value is returned.
  /// If the value is an `int`, it is converted to a `double`.
  /// If the value is a `String`, an attempt is made to parse it as a `double` using the [attemptToGetDoubleFromText] function, and the result is returned or the default value is returned if the parsing fails.
  /// If the value is a `double`, it is returned as is.
  ///
  /// @param key The key to retrieve the double value for.
  /// @param defaultIfNotFound The default value to return if the key is not found or the value cannot be parsed as a double. Defaults to `0.0`.
  /// @return The double value associated with the key, or the default value if the key is not found or the value cannot be parsed as a double.
  double getDouble(String key, [double defaultIfNotFound = 0.0]) {
    final dynamic value = this[key];
    if (value == null) {
      return defaultIfNotFound;
    }
    try {
      if (value is int) {
        return value.toDouble();
      }
      if (value is String) {
        return attemptToGetDoubleFromText(value) ?? 0.0;
      }
      return value as double;
    } catch (_) {
      return defaultIfNotFound;
    }
  }

  /// Retrieves an integer value from the JSON object for the given key.
  ///
  /// If the value for the specified key is `null`, the provided [defaultIfNotFound] value is returned.
  /// If the value is an `int`, it is returned as is.
  /// If the value is a `String`, an attempt is made to parse it as an `int` using [int.parse], and the result is returned or the default value is returned if the parsing fails.
  ///
  /// @param key The key to retrieve the integer value for.
  /// @param defaultIfNotFound The default value to return if the key is not found or the value cannot be parsed as an integer. Defaults to `0`.
  /// @return The integer value associated with the key, or the default value if the key is not found or the value cannot be parsed as an integer.
  int getInt(String key, [int defaultIfNotFound = 0]) {
    final dynamic value = this[key];
    if (value == null) {
      return defaultIfNotFound;
    }
    try {
      if (value is int) {
        return value;
      }
      return int.parse(value as String);
    } catch (_) {
      return defaultIfNotFound;
    }
  }

  /// Retrieves a string value from the JSON object for the given key.
  ///
  /// If the value for the specified key is `null`, the provided [defaultIfNotFound] value is returned.
  /// If the value is a `String`, it is returned as is.
  ///
  /// @param key The key to retrieve the string value for.
  /// @param defaultIfNotFound The default value to return if the key is not found or the value cannot be parsed as a string. Defaults to an empty string.
  /// @return The string value associated with the key, or the default value if the key is not found or the value cannot be parsed as a string.
  String getString(String key, [String defaultIfNotFound = '']) {
    final dynamic value = this[key];
    if (value == null) {
      return defaultIfNotFound;
    }
    try {
      return value as String;
    } catch (_) {
      return defaultIfNotFound;
    }
  }

  /// Generic converter the caller is responsible
  /// This may throw an exception
  T? getValue<T>(String key, {T? defaultValue}) {
    if (containsKey(key)) {
      return this[key] as T;
    }
    return defaultValue;
  }

  /// Decodes the provided JSON string and returns the result as an instance of type [T].
  ///
  /// This method uses [jsonDecode] to parse the JSON string and then casts the result to the
  /// specified generic type [T]. It is the caller's responsibility to ensure that the JSON
  /// string can be successfully deserialized into the target type.
  ///
  /// Example usage:
  ///
  /// ```final myObject = JsonHelper.fromJson<MyClass>('{"key":"value"}');```
  ///
  static T fromJson<T>(String jsonString) {
    return jsonDecode(jsonString) as T;
  }

  /// Converts object to JSON string.
  static String toJson(dynamic object) {
    return jsonEncode(object);
  }
}

/// Converts raw CSV text content into a list of [MyJson] objects.
///
/// The function takes a [fileContent] string, which is expected to be in CSV format.
/// It parses the sheet content, extracts the header columns, and then creates a list
/// of [MyJson] objects, where each object represents a row in the CSV data.
///
/// The function assumes that the CSV file has at least one row of data (excluding the header).
/// If the CSV file is empty or has only the header row, an empty list will be returned.
///
/// Example usage:
///
/// final csvContent = await readFile('data.csv');
/// final jsonObjects = convertFromRawCsvTextToListOfJSonObject(csvContent);
///
List<MyJson> convertFromRawCsvTextToListOfJSonObject(String fileContent) {
  final List<MyJson> rows = <MyJson>[];
  final List<List<String>> lines = getLinesFromRawTextWithSeparator(
    fileContent,
  );
  if (lines.length > 1) {
    final List<String> csvHeaderColumns = lines.first
        .map((String header) => removeUtf8Bom(header))
        .toList(growable: false);
    for (final List<String> csvRowValues in lines.skip(1)) {
      if (_isEmptyCsvRow(csvRowValues)) {
        continue;
      }
      final List<String> normalizedCsvRowValues = _normalizeCsvRowValues(
        csvRowValues,
        csvHeaderColumns.length,
      );
      final MyJson rowValues = myJsonFromKeyValuePairs(
        csvHeaderColumns,
        normalizedCsvRowValues,
      );
      rows.add(rowValues);
    }
  }
  return rows;
}

/// Returns true when every cell in [row] is empty or whitespace.
bool _isEmptyCsvRow(List<String> row) {
  return row.every((String value) => value.trim().isEmpty);
}

/// Normalizes [row] so it matches [expectedColumnCount] by trimming extras and padding missing values.
List<String> _normalizeCsvRowValues(
  List<String> row,
  int expectedColumnCount,
) {
  final List<String> normalizedValues = List<String>.filled(
    expectedColumnCount,
    '',
  );
  final int sharedColumnCount = row.length < expectedColumnCount ? row.length : expectedColumnCount;
  for (int i = 0; i < sharedColumnCount; i++) {
    normalizedValues[i] = row[i];
  }
  return normalizedValues;
}
