// ignore: fcheck_dead_code
import 'dart:math';

import 'package:money/helpers/pairs_model.dart';
import 'package:money/helpers/string_helper.dart';

/// Returns the sort direction after the user taps the header of [tappedColumn]:
/// tapping the column already sorted on ([sortedColumn]) flips [ascending],
/// tapping another column keeps it. The tapped column becomes the sorted column.
bool sortAscendingAfterColumnTap(int tappedColumn, int sortedColumn, bool ascending) =>
    tappedColumn == sortedColumn ? !ascending : ascending;

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

/// Returns list with min and max values from the input list.
List<num> getMinMaxValues(List<double> list) {
  if (list.isEmpty) {
    return <num>[0, 0];
  }
  return <num>[list.reduce(min), list.reduce(max)];
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
  DateTime? a,
  DateTime? b, [
  bool ascending = true,
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
int sortByString(dynamic a, dynamic b, bool ascending) {
  if (ascending) {
    return stringCompareIgnoreCasing(a.toString(), b.toString());
  } else {
    return stringCompareIgnoreCasing(b.toString(), a.toString());
  }
}

/// Sorts items by numeric value comparison.
int sortByValue(num a, num b, bool ascending) {
  if (ascending) {
    return a.compareTo(b);
  } else {
    return b.compareTo(a);
  }
}

/// Converts enum values to list of strings.
List<String> enumToStringList<T>(List<T> enumValues) {
  return enumValues.map((T e) => e.toString().split('.').last).toList();
}

/// Returns the value of [values] at [index], or [fallback] when [index] is out of range.
T enumFromIndex<T extends Enum>(List<T> values, int index, T fallback) {
  return isIndexInRange(values, index) ? values[index] : fallback;
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
