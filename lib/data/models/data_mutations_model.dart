import 'package:flutter/foundation.dart';

/// Tracking changes of data
class DataMutations extends ChangeNotifier {
  /// Creates a mutable tracker for add/change/delete counters.
  DataMutations();

  int added = 0;
  int changed = 0;
  int deleted = 0;
  DateTime lastDateTimeChanged = DateTime.now();

  /// Increments mutation counters and updates the last edit time.
  void increaseNumber({
    int increaseAdded = 0,
    int increaseChanged = 0,
    int increaseDeleted = 0,
  }) {
    setLastEditToNow();
    added += increaseAdded;
    changed += increaseChanged;
    deleted += increaseDeleted;
    notifyListeners();
  }

  /// Indicate of any data has changed Added or Deleted
  bool isMutated() {
    return numberOfChanges() > 0;
  }

  /// Returns the total number of mutations.
  int numberOfChanges() {
    return added + changed + deleted;
  }

  /// Resets all mutation counters and updates the last edit time.
  void reset() {
    setLastEditToNow();
    added = 0;
    changed = 0;
    deleted = 0;
    notifyListeners();
  }

  /// Updates [lastDateTimeChanged] to now.
  void setLastEditToNow() {
    lastDateTimeChanged = DateTime.now();
    notifyListeners();
  }
}
