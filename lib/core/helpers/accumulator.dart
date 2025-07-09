import 'package:money/core/helpers/misc_helpers.dart';
import 'package:money/core/helpers/ranges.dart';

/// Generic accumulator for collecting values by key.
/// Features:
/// - Type-safe value accumulation
/// - Set-based storage
/// - Key-value lookups
class AccumulatorList<K, V> {
  final Map<K, Set<V>> values = <K, Set<V>>{};

  void clear() {
    values.clear();
  }

  bool containsKey(K key) {
    return values.containsKey(key);
  }

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

  void clear() {
    values.clear();
  }

  bool containsKey(K key) {
    return values.containsKey(key);
  }

  void cumulate(K key, V value) {
    if (values.containsKey(key)) {
      // Use dynamic type for accumulated value as specific behavior depends on T
      final V? existingValue = values[key];
      values[key] = _accumulate(existingValue as V, value) as V;
    } else {
      values[key] = value;
    }
  }

  List<MapEntry<K, V>> getEntries() => values.entries.toList();

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

  void clear() {
    values.clear();
  }

  bool containsKey(final K key) => values.containsKey(key);

  void cumulate(final K key, final DateTime value) {
    if (values.containsKey(key)) {
      values[key]!.inflate(value);
    } else {
      values[key] = DateRange()..inflate(value);
    }
  }

  List<MapEntry<K, DateRange>> getEntries() => values.entries.toList();

  DateRange? getValue(final K key) => values[key];
}

/// Calculates running averages for values by key.
/// Features:
/// - Running average calculation
/// - Count tracking
/// - Zero value handling
class AccumulatorAverage<K> {
  final Map<K, RunningAverage> values = <K, RunningAverage>{};

  void clear() {
    values.clear();
  }

  bool containsKey(final K key) => values.containsKey(key);

  void cumulate(final K key, final num value) {
    final RunningAverage average = values.containsKey(key) ? values[key]! : values[key] = RunningAverage();
    average.addValue(value);
  }

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

  void clear() {
    values.clear();
    highWatermark.clear();
    lowWatermark.clear();
  }

  bool containsKey(final K key) => values.containsKey(key);

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

  RunningAverage? getValue(final K key) => values[key];

  num? getHighWatermark(final K key) => highWatermark[key];

  num? getLowWatermark(final K key) => lowWatermark[key];
}

/// Two-level accumulator mapping keys to sums.
/// Features:
/// - Nested key structure
/// - Sum accumulation
/// - Level-based access
class MapAccumulatorSum<K, I, V> {
  Map<K, AccumulatorSum<I, V>> map = <K, AccumulatorSum<I, V>>{};

  void cumulate(K k, I i, V v) {
    if (!map.containsKey(k)) {
      map[k] = AccumulatorSum<I, V>();
    }
    map[k]!.cumulate(i, v);
  }

  AccumulatorSum<I, V>? getLevel1(K key) => map[key];
}

/// Two-level accumulator mapping keys to sets.
/// Features:
/// - Nested key structure
/// - Set-based storage
/// - Level-based access
class MapAccumulatorSet<K, I, V> {
  Map<K, AccumulatorList<I, V>> map = <K, AccumulatorList<I, V>>{};

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

  void addValue(num newValue) {
    if (isConsideredZero(newValue)) {
      _countZeros++;
    } else {
      _sum += newValue;
      _count++;
      range.inflate(newValue);
    }
  }

  String get descriptionAsInt => 'Average\n${range.descriptionAsInt}\n$descriptionCount';

  String get descriptionAsMoney => 'Average\n${range.descriptionAsMoney}\n$descriptionCount';

  String get descriptionCount {
    if (_countZeros == 0) {
      return '$_count entries.';
    }
    return '$_count of ${_count + _countZeros} non zero entries.';
  }

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
