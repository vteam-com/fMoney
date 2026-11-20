/// Separator of ids the model sends as one text, like "12, 14".
const String _listSeparator = ',';

/// Text the model may send for a true argument.
const String _trueText = 'true';

/// Text the model may send for a false argument.
const String _falseText = 'false';

/// Lenient readers for the arguments a model passes to a tool: models sometimes send numbers and
/// booleans as text, so each reader accepts both and returns null (or empty) when the value is unusable.
extension AiToolArgs on Map<String, dynamic> {
  /// Returns the true/false argument [key], or null when missing or not a boolean.
  bool? boolArg(String key) {
    final Object? value = this[key];
    if (value is bool) {
      return value;
    }
    final String text = value?.toString().trim().toLowerCase() ?? '';
    return text == _trueText ? true : (text == _falseText ? false : null);
  }

  /// Returns the date argument [key] (like 2024-03-31), or null when missing or not a date.
  DateTime? dateArg(String key) => DateTime.tryParse(stringArg(key));

  /// Returns the decimal argument [key], or null when missing or not a number.
  double? doubleArg(String key) {
    final Object? value = this[key];
    return value is num ? value.toDouble() : double.tryParse(value?.toString().trim() ?? '');
  }

  /// Returns the whole-number argument [key], or null when missing or not a number.
  int? intArg(String key) {
    final Object? value = this[key];
    if (value is int) {
      return value;
    }
    return value is num ? value.toInt() : int.tryParse(value?.toString().trim() ?? '');
  }

  /// Returns the list-of-ids argument [key], given as a list or as comma-separated text; empty when missing.
  List<int> intListArg(String key) {
    final Object? value = this[key];
    final Iterable<Object?> items = value is List ? value : (value?.toString().split(_listSeparator) ?? <String>[]);
    return items
        .map((Object? item) => item is num ? item.toInt() : int.tryParse(item.toString().trim()))
        .whereType<int>()
        .toList();
  }

  /// Returns the text argument [key] trimmed, or an empty string when missing.
  String stringArg(String key) => this[key]?.toString().trim() ?? '';
}
