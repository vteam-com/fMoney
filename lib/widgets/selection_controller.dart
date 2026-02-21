import 'package:get/get.dart';
import 'package:money/widgets/preferences_controller.dart';

// List the selected item IDs, optionally can be persisted and loaded in Preferences
/// Controller for managing selected item IDs in lists.
/// Features:
/// - Track multiple selected items using a RxSet
/// - Persist selections to preferences using a key
/// - Toggle individual item selection
/// - Support for first selected ID retrieval
class SelectionController extends GetxController {
  SelectionController([this.preferenceKeyForPersistingSelections = '']) {
    if (preferenceKeyForPersistingSelections.isNotEmpty) {
      load();
    }
  }

  String preferenceKeyForPersistingSelections = '';
  RxSet<int> selectedItems = <int>{}.obs;

  /// Returns the first selected ID or -1 if none selected.
  int get firstSelectedId {
    if (selectedItems.isEmpty) {
      return -1;
    }
    return selectedItems.first;
  }

  // Function to check if an item is selected
  /// Checks whether the item with [id] is currently selected.
  bool isSelected(int id) {
    return selectedItems.contains(id);
  }

  /// Loads the last selected ID from preferences and selects it.
  void load() {
    if (preferenceKeyForPersistingSelections.isNotEmpty) {
      final int lastSelectionId = PreferenceController.to.getInt(
        preferenceKeyForPersistingSelections,
        -1,
      );
      select(lastSelectionId);
    }
  }

  /// Persists the first selected ID to preferences.
  void save() {
    if (preferenceKeyForPersistingSelections.isNotEmpty) {
      PreferenceController.to.setInt(
        preferenceKeyForPersistingSelections,
        firstSelectedId,
      );
    }
  }

  /// Selects a single [id] and persists the choice.
  void select(int id) {
    selectedItems.clear();
    if (id != -1) {
      selectedItems.add(id);
    }
    save();
  }

  /// Singleton accessor for the registered SelectionController.
  static SelectionController get to => Get.find();

  // Function to toggle selection
  /// Toggles selection state for the given [id].
  void toggleSelection(int id) {
    if (selectedItems.contains(id)) {
      selectedItems.remove(id);
    } else {
      selectedItems.add(id);
    }
  }
}
