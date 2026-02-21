// ignore: fcheck_dead_code
import 'dart:math';
import 'package:money/helpers/pairs.dart';
import 'package:money/helpers/string_helper.dart';

/// Calculates a list of evenly spaced values between a start and end value.
///
/// This function takes a start value, an end value, and the desired number of
/// entries in the resulting list. It calculates the step size between each
/// value and generates a list of evenly spaced values between the start and
/// end values.
///
/// If the number of entries is less than or equal to 1, an empty list is
/// returned.
///
/// Example usage:
///
/// ```dart
/// List<double> spread = calculateSpread(1.0, 5.0, 5);
/// print(spread); // Output: [1.0, 2.0, 3.0, 4.0, 5.0]
/// ```
///
/// Parameters:
///   start (double): The starting value of the spread.
///   end (double): The ending value of the spread.
///   numEntries (int): The desired number of entries in the resulting list.
///
/// Returns:
///   A list of evenly spaced values between the start and end values.
///   If numEntries is less than or equal to 1, an empty list is returned.
List<double> calculateSpread(double start, double end, int numEntries) {
  // Check if numEntries is valid
  if (numEntries <= 1) {
    return <double>[];
  }

  // Calculate the step size between each value
  final double step = (end - start) / (numEntries - 1);

  // Initialize an empty list to store the spread values
  final List<double> spread = <double>[];

  // Generate the spread values and add them to the list
  for (int i = 0; i < numEntries; i++) {
    spread.add(start + i * step);
  }

  return spread;
}

/// Converts a Map to a List of Pair objects.
///
/// This function takes a Map and converts it to a List of Pair objects,
/// where each Pair object contains a key-value pair from the input Map.
///
/// The function is generic and can handle any type of key and value in the
/// input Map. The types of the key and value are specified using the type
/// parameters `T` and `U`, respectively.
///
/// Example usage:
///
/// ```dart
/// Map<String, int> myMap = {'apple': 1, 'banana': 2, 'orange': 3};
/// List<Pair<String, int>> pairList = convertMapToListOfPair<String, int>(myMap);
/// print(pairList); // Output: [(apple, 1), (banana, 2), (orange, 3)]
/// ```
///
/// Parameters:
///   map (```Map<dynamic, dynamic>```): The input Map to be converted.
///
/// Type Parameters:
///   T: The type of the keys in the input Map.
///   U: The type of the values in the input Map.
///
/// Returns:
///   A List of Pair objects, where each Pair contains a key-value pair
///   from the input Map.
List<Pair<T, U>> convertMapToListOfPair<T, U>(Map<dynamic, dynamic> map) {
  // Initialize an empty list to store the Pair objects
  final List<Pair<T, U>> list = <Pair<T, U>>[];

  // Iterate over the entries in the input Map
  map.forEach((dynamic key, dynamic value) {
    // Create a Pair object with the current key and value
    list.add(Pair<T, U>(key as T, value as U));
  });

  // Return the list of Pair objects
  return list;
}

/// Converts a list of key-value pairs to a list of percentages.
///
/// This function takes a list of [PairStringDouble] objects, which represent
/// key-value pairs where the value is a number. It calculates the total
/// amount of all the values, then converts each value to a percentage of
/// the total and returns a new list of [PairStringDouble] objects with the
/// updated percentage values.
///
/// If any of the values are zero, the corresponding percentage is set to 0.0
/// to handle division by zero.
///
/// Parameters:
///   `PairStringDouble (List<PairStringDouble>)`: The input list of key-value pairs.
///
/// Returns:
///   A new list of [PairStringDouble] objects with the values converted to
///   percentages of the total.
List<PairStringDouble> convertToPercentages(
  List<PairStringDouble> pairStringDouble,
) {
  // Calculate total amount
  final double totalAmount = pairStringDouble.fold(
    0,
    (double prev, PairStringDouble entry) => prev + (entry.value as num),
  );

  // Convert each amount to a percentage and retain key association
  final List<PairStringDouble> percentages = pairStringDouble.map((PairStringDouble entry) {
    final double percentage = ((entry.value as num) / totalAmount) * 100;
    return PairStringDouble(
      key: entry.key,
      value: percentage.isNaN ? 0.0 : percentage,
    ); // Handle division by zero
  }).toList();

  return percentages;
}

/// Returns list with min and max values from the input list.
List<num> getMinMaxValues(final List<double> list) {
  if (list.isEmpty) {
    return <num>[0, 0];
  }
  if (list.length == 1) {
    return <num>[list[0], list[0]];
  }

  double valueMin = 0.0;
  double valueMax = 0.0;
  if (list[0] < list[1]) {
    valueMin = list[0];
    valueMax = list[1];
  } else {
    valueMin = list[1];
    valueMax = list[0];

    for (double value in list) {
      valueMin = min(valueMin, value);
      valueMax = max(valueMax, value);
    }
  }
  return <num>[valueMin, valueMax];
}

/// Checks if index is within valid range for the array.
bool isIndexInRange(List<dynamic> array, int index) {
  return index >= 0 && index < array.length;
}

/// Pads list to specified length with padding string.
List<String> padList(List<String> list, int length, String padding) {
  if (list.length >= length) {
    return list;
  }
  final List<String> paddedList = List<String>.from(list);
  for (int i = list.length; i < length; i++) {
    paddedList.add(padding);
  }
  return paddedList;
}

/// Sorts items by date comparison.
int sortByDate(
  final DateTime? a,
  final DateTime? b, [
  final bool ascending = true,
]) {
  if (a == null && b == null) {
    return 0;
  }

  if (ascending) {
    if (a == null) {
      return -1;
    }
    if (b == null) {
      return 1;
    }
    return a.compareTo(b);
  } else {
    if (a == null) {
      return 1;
    }
    if (b == null) {
      return -1;
    }
    return b.compareTo(a);
  }
}

/// Sorts items by string comparison.
int sortByString(final dynamic a, final dynamic b, final bool ascending) {
  if (ascending) {
    return stringCompareIgnoreCasing(a.toString(), b.toString());
  } else {
    return stringCompareIgnoreCasing(b.toString(), a.toString());
  }
}

/// Sorts items by numeric value comparison.
int sortByValue(final num a, final num b, final bool ascending) {
  if (ascending) {
    return a.compareTo(b);
  } else {
    return b.compareTo(a);
  }
}

/// Converts enum values to list of strings.
List<String> enumToStringList<T>(List<T> enumValues) {
  return enumValues.map((final T e) => e.toString().split('.').last).toList();
}

extension RandomItemExtension<T> on List<T> {
  /// Returns random item from the list.
  T getRandomItem() {
    final Random random = Random();
    if (isEmpty) {
      throw Exception('Cannot get random item from an empty list');
    }
    return this[random.nextInt(length)];
  }
}
