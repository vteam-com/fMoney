// ignore: fcheck_one_class_per_file
// ignore: fcheck_dead_code

import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/ranges.dart';
import 'package:money/helpers/shared_strings.dart';

/// Generic accumulator for collecting values by key.
/// Features:
/// - Type-safe value accumulation
/// - Set-based storage
/// - Key-value lookups
class AccumulatorList<K, V> {
  final Map<K, Set<V>> values = <K, Set<V>>{};

  /// Clears all accumulated values.
  void clear() {
    values.clear();
  }

  /// Returns true if the accumulator contains the specified key.
  bool containsKey(K key) {
    return values.containsKey(key);
  }

  /// Returns true if the accumulator contains the specified key-value pair.
  bool containsKeyValue(K key, V value) {
    final Set<V>? setFound = values[key];
    if (setFound == null) {
      // the key is not a match
      return false;
    }

    return setFound.contains(value);
  }

  /// Adds a value of type `V` to the set associated with the provided `key` of type `K`.
  ///
  /// If the `key` already exists in the `values` map, it retrieves the existing set
  /// and adds the `value` to that set. If the `key` doesn't exist, it creates a new
  /// set containing the `value` and associates it with the `key` in the `values` map.
  void cumulate(K key, V value) {
    if (values.containsKey(key)) {
      final Set<V> existingSet = values[key] as Set<V>;
      existingSet.add(value);
    } else {
      // first time setting the set
      values[key] = <V>{value}; // Ensure type safety for the set
    }
  }

  /// Returns a list of all the keys present in the `values` map.
  List<K> getKeys() {
    return values.keys.toList();
  }

  /// Retrieves the set of values associated with the provided `key`.
  ///
  /// If the `key` exists in the `values` map, it converts the set to a list and returns it.
  /// If the `key` doesn't exist, it returns an empty list.
  List<V> getList(K key) {
    return values[key]?.toList() ?? <V>[];
  }

  /// Returns the set of values for the specified key, or null if not found.
  Set<V>? getValue(K key) {
    return values[key];
  }
}

/// Accumulator for numeric sums mapped to keys.
/// Features:
/// - Generic numeric value support
/// - Running sum calculation
/// - Max value tracking
class AccumulatorSum<K, V> {
  final Map<K, V> values = <K, V>{};

  /// Clears all accumulated sum values.
  void clear() {
    values.clear();
  }

  /// Returns true if the accumulator contains the specified key.
  bool containsKey(K key) {
    return values.containsKey(key);
  }

  /// Accumulates the value for the specified key, adding to existing sum.
  void cumulate(K key, V value) {
    if (values.containsKey(key)) {
      // Use dynamic type for accumulated value as specific behavior depends on T
      final V? existingValue = values[key];
      values[key] = _accumulate(existingValue as V, value) as V;
    } else {
      values[key] = value;
    }
  }

  /// Returns a list of all key-value entries in the accumulator.
  ///
  /// Each entry in the list is a [MapEntry] containing a key of type [K] and a value of type [V].
  List<MapEntry<K, V>> getEntries() => values.entries.toList();

  /// Returns the key with the largest accumulated sum value.
  ///
  /// If multiple keys have the same maximum sum, any of them may be returned.
  /// If the accumulator is empty, returns null.
  K? getKeyWithLargestSum() {
    K? keyFound;
    V? maxFound;

    values.forEach((K key, V value) {
      if (keyFound == null) {
        keyFound = key;
        maxFound = value;
      } else {
        if ((maxFound as num) < (value as num)) {
          keyFound = key;
          maxFound = value;
        }
      }
    });
    return keyFound;
  }

  /// Returns the accumulated value for the specified key, or 0 if not found.
  dynamic getValue(final K key) => values[key] ?? 0;

  // Replace this function with your specific logic for accumulating values of type T
  dynamic _accumulate(V existingValue, V value) => (existingValue as num) + (value as num);
}

/// Tracks date ranges for values by key.
/// Features:
/// - Min/max date tracking
/// - Date range expansion
/// - Range retrieval
class AccumulatorDateRange<K> {
  final Map<K, DateRange> values = <K, DateRange>{};

  /// Clears all accumulated date ranges.
  void clear() {
    values.clear();
  }

  /// Returns true if the accumulator contains the specified key.
  bool containsKey(final K key) => values.containsKey(key);

  /// Accumulates the date value for the specified key, expanding the date range.
  void cumulate(final K key, final DateTime value) {
    if (values.containsKey(key)) {
      values[key]!.inflate(value);
    } else {
      values[key] = DateRange()..inflate(value);
    }
  }

  /// Returns list of all key-date range entries in the accumulator.
  List<MapEntry<K, DateRange>> getEntries() => values.entries.toList();

  /// Returns the date range for the specified key, or null if not found.
  DateRange? getValue(final K key) => values[key];
}

/// Calculates running averages for values by key.
/// Features:
/// - Running average calculation
/// - Count tracking
/// - Zero value handling
class AccumulatorAverage<K> {
  final Map<K, RunningAverage> values = <K, RunningAverage>{};

  /// Clears all accumulated average values.
  void clear() {
    values.clear();
  }

  /// Returns true if the accumulator contains the specified key.
  bool containsKey(final K key) => values.containsKey(key);

  /// Accumulates the value for the specified key, updating the running average.
  void cumulate(final K key, final num value) {
    final RunningAverage average = values.containsKey(key) ? values[key]! : values[key] = RunningAverage();
    average.addValue(value);
  }

  /// Returns the running average for the specified key, or null if not found.
  RunningAverage? getValue(final K key) => values[key];
}

/// Calculates running range for values by key.
/// Features:
/// - Running min, average, max calculation
/// - Count tracking
/// - Zero value handling
/// - High/low watermark tracking
class AccumulatorRange<K> {
  final Map<K, RunningAverage> values = <K, RunningAverage>{};
  final Map<K, num> highWatermark = <K, num>{};
  final Map<K, num> lowWatermark = <K, num>{};

  /// Clears all accumulated range values and watermarks.
  void clear() {
    values.clear();
    highWatermark.clear();
    lowWatermark.clear();
  }

  /// Returns true if the accumulator contains the specified key.
  bool containsKey(final K key) => values.containsKey(key);

  /// Accumulates the value for the specified key, updating range and watermarks.
  void cumulate(final K key, final num value) {
    final RunningAverage average = values.containsKey(key) ? values[key]! : values[key] = RunningAverage();
    average.addValue(value);

    // Update high/low watermarks
    if (!highWatermark.containsKey(key) || value > highWatermark[key]!) {
      highWatermark[key] = value;
    }
    if (!lowWatermark.containsKey(key) || value < lowWatermark[key]!) {
      lowWatermark[key] = value;
    }
  }

  /// Returns the running average for the specified key, or null if not found.
  RunningAverage? getValue(final K key) => values[key];

  /// Returns the high watermark value for the specified key, or null if not found.
  num? getHighWatermark(final K key) => highWatermark[key];

  /// Returns the low watermark value for the specified key, or null if not found.
  num? getLowWatermark(final K key) => lowWatermark[key];
}

/// Two-level accumulator mapping keys to sums.
/// Features:
/// - Nested key structure
/// - Sum accumulation
/// - Level-based access
class MapAccumulatorSum<K, I, V> {
  Map<K, AccumulatorSum<I, V>> map = <K, AccumulatorSum<I, V>>{};

  /// Accumulates the value for the nested key structure.
  void cumulate(K k, I i, V v) {
    if (!map.containsKey(k)) {
      map[k] = AccumulatorSum<I, V>();
    }
    map[k]!.cumulate(i, v);
  }

  /// Returns the level-1 accumulator for the specified key, or null if not found.
  AccumulatorSum<I, V>? getLevel1(K key) => map[key];
}

/// Two-level accumulator mapping keys to sets.
/// Features:
/// - Nested key structure
/// - Set-based storage
/// - Level-based access
class MapAccumulatorSet<K, I, V> {
  Map<K, AccumulatorList<I, V>> map = <K, AccumulatorList<I, V>>{};

  /// Accumulates the value for the nested key structure using set storage.
  void cumulate(K k, I i, V v) {
    if (!map.containsKey(k)) {
      map[k] = AccumulatorList<I, V>();
    }
    map[k]!.cumulate(i, v);
  }

  /// Retrieves the set of values [V] associated with the given keys [K] and [I].
  /// If no values are found for the given keys, an empty set is returned.
  Set<V> find(final K key1, final I key2) {
    final AccumulatorList<I, V>? foundInLevel1 = map[key1];
    return foundInLevel1?.getValue(key2) ?? <V>{};
  }

  /// Returns the level-1 accumulator for the specified key, or null if not found.
  AccumulatorList<I, V>? getLevel1(final K key1) => map[key1];
}

/// Tracks running statistics for numeric values.
/// Features:
/// - Count tracking
/// - Sum calculation
/// - Zero handling
/// - Min/max range
class RunningAverage {
  NumRange range = NumRange(min: double.infinity, max: -double.infinity);

  int _count = 0;
  int _countZeros = 0;
  num _sum = 0.0;

  /// Adds a new value to the running average calculation.
  void addValue(num newValue) {
    if (isConsideredZero(newValue)) {
      _countZeros++;
    } else {
      _sum += newValue;
      _count++;
      range.inflate(newValue);
    }
  }

  /// Returns formatted description with average as integer and count.
  String get descriptionAsInt =>
      '${SharedStrings.runningAverageLabel}${SharedStrings.lineFeed}'
      '${range.descriptionAsInt}${SharedStrings.lineFeed}$descriptionCount';

  /// Returns formatted description with average as money and count.
  String get descriptionAsMoney =>
      '${SharedStrings.runningAverageLabel}${SharedStrings.lineFeed}'
      '${range.descriptionAsMoney}${SharedStrings.lineFeed}$descriptionCount';

  /// Returns formatted count description including zero values.
  String get descriptionCount {
    if (_countZeros == 0) {
      return '$_count${SharedStrings.runningAverageEntriesSuffix}';
    }
    return '$_count'
        '${SharedStrings.runningAverageOfInfix}'
        '${_count + _countZeros}'
        '${SharedStrings.runningAverageNonZeroEntriesSuffix}';
  }

  /// Returns the calculated average, optionally including zero values.
  double getAverage({final bool includingZeros = false}) {
    if (_count == 0) {
      return 0.0; // Handle case where no values have been added yet
    }
    if (includingZeros) {
      return _sum / (_count + _countZeros);
    }
    return _sum / _count;
  }
}
