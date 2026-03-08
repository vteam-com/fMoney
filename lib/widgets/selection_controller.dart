import 'package:money/widgets/preferences_controller.dart';

// List the selected item IDs, optionally can be persisted and loaded in Preferences
/// Controller for managing selected item IDs in lists.
/// Features:
/// - Track multiple selected items using a RxSet
/// - Persist selections to preferences using a key
/// - Toggle individual item selection
/// - Support for first selected ID retrieval
class SelectionController {
  SelectionController([this.preferenceKeyForPersistingSelections = '']) {
    SelectionController._lastCreated = this;
    if (preferenceKeyForPersistingSelections.isNotEmpty) {
      load();
    }
  }

  static SelectionController? _lastCreated;

  String preferenceKeyForPersistingSelections = '';
  final Set<int> selectedItems = <int>{};

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

  /// Returns the most recently created selection controller.
  static SelectionController get to {
    assert(_lastCreated != null, 'SelectionController.to accessed before any SelectionController was created.');
    return _lastCreated!;
  }
}
