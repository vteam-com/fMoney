import 'package:money/widgets_data/money_object/money_model.dart';

/// Returns the provided [value] if it's not null, otherwise returns the [defaultValueIfNull].
///
/// This function is useful when dealing with nullable boolean values and ensuring a non-null value
/// is returned, even if the provided value is null.
///
/// Example:
/// ```dart
/// bool isActive = valueOrDefaultBool(null, defaultValueIfNull: true); // isActive = true
/// bool isEnabled = valueOrDefaultBool(false); // isEnabled = false
/// ```
bool valueOrDefaultBool(
  final bool? value, {
  final bool defaultValueIfNull = false,
}) {
  return value ?? defaultValueIfNull;
}

/// Returns the provided [value] if it's not null, otherwise returns the [defaultValueIfNull].
/// If [defaultValueIfNull] is null, it returns the current date and time.
///
/// This function is useful when dealing with nullable DateTime values and ensuring a non-null value
/// is returned, even if the provided value is null.
///
/// Example:
/// ```dart
/// DateTime dueDate = valueOrDefaultDate(null, defaultValueIfNull: DateTime(2023, 6, 1));
/// DateTime currentDate = valueOrDefaultDate(null); // currentDate = DateTime.now()
/// ```
DateTime valueOrDefaultDate(
  final DateTime? value, {
  final DateTime? defaultValueIfNull,
}) {
  return value ?? defaultValueIfNull ?? DateTime.now();
}

/// Returns the provided [value] if it's not null, otherwise returns the [defaultValueIfNull].
///
/// This function is useful when dealing with nullable double values and ensuring a non-null value
/// is returned, even if the provided value is null.
///
/// Example:
/// ```dart
/// double price = valueOrDefaultDouble(null, defaultValueIfNull: 9.99); // price = 9.99
/// double amount = valueOrDefaultDouble(10.5); // amount = 10.5
/// ```
double valueOrDefaultDouble(
  final double? value, {
  final double defaultValueIfNull = 0,
}) {
  return value ?? defaultValueIfNull;
}

/// Returns the provided [value] if it's not null, otherwise returns the [defaultValueIfNull].
///
/// This function is useful when dealing with nullable integer values and ensuring a non-null value
/// is returned, even if the provided value is null.
///
/// Example:
/// ```dart
/// int count = valueOrDefaultInt(null, defaultValueIfNull: 10); // count = 10
/// int age = valueOrDefaultInt(25); // age = 25
/// ```
int valueOrDefaultInt(final int? value, {final int defaultValueIfNull = 0}) {
  return value ?? defaultValueIfNull;
}

/// Returns the provided [value] if it's not null, otherwise returns the [defaultValueIfNull].
///
/// This function is useful when dealing with nullable numeric values (either int or double)
/// and ensuring a non-null value is returned, even if the provided value is null.
///
/// Example:
/// ```dart
/// num quantity = numValueOrDefault(null, defaultValueIfNull: 5); // quantity = 5
/// num price = numValueOrDefault(10.99); // price = 10.99
/// ```
num numValueOrDefault(final num? value, {final num defaultValueIfNull = 0}) {
  return value ?? defaultValueIfNull;
}

/// Returns the provided [value] if it's not null, otherwise returns the [defaultValueIfNull].
///
/// This function is useful when dealing with nullable string values and ensuring a non-null value
/// is returned, even if the provided value is null.
///
/// Example:
/// ```dart
/// String name = valueOrDefaultString(null, defaultValueIfNull: 'Unknown'); // name = 'Unknown'
/// String description = valueOrDefaultString('This is a description'); // description = 'This is a description'
/// ```
String valueOrDefaultString(
  final String? value, {
  final String defaultValueIfNull = '',
}) {
  return value ?? defaultValueIfNull;
}

double smartToDouble(final dynamic value) {
  if (value is double) {
    return value;
  }

  if (value is int) {
    return value.toDouble();
  }

  if (value is MoneyModel) {
    return value.asDouble();
  }

  return value as double;
}
