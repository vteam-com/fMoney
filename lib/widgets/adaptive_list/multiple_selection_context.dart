import 'package:flutter/material.dart';

// Exports
export 'package:flutter/material.dart';
export 'package:money/widgets/scale_down.dart';

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
