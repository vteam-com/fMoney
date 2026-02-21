import 'package:get/get.dart';

/// Tracking changes of data
class DataMutations extends GetxController {
  RxInt added = 0.obs;
  RxInt changed = 0.obs;
  RxInt deleted = 0.obs;
  Rx<DateTime> lastDateTimeChanged = Rx<DateTime>(DateTime.now());

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
  }

  /// Indicate of any data has changed Added or Deleted
  bool isMutated() {
    return numberOfChanges() > 0;
  }

  /// Returns the total number of mutations.
  int numberOfChanges() {
    return added.value + changed.value + deleted.value;
  }

  /// Resets all mutation counters and updates the last edit time.
  void reset() {
    setLastEditToNow();
    added.value = 0;
    changed.value = 0;
    deleted.value = 0;
  }

  /// Updates [lastDateTimeChanged] to now.
  void setLastEditToNow() {
    lastDateTimeChanged.value = DateTime.now();
  }

  /// Returns the registered instance from GetX.
  static DataMutations get to => Get.find();
}
