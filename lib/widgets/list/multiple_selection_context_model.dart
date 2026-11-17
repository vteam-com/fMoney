import 'package:material_ui/material_ui.dart';

// Exports
export 'package:material_ui/material_ui.dart';
export 'package:money/widgets/pure/scale_down_widget.dart';

/// Represents view header multiple selection.
class ViewHeaderMultipleSelection {
  ViewHeaderMultipleSelection({
    required this.onToggleMode,
    required this.isMultiSelectionOn,
    required this.selectedItems,
  });

  final bool isMultiSelectionOn;
  final VoidCallback? onToggleMode;
  final ValueNotifier<List<int>> selectedItems;
}
