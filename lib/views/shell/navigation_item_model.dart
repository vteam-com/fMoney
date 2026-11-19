import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/constants_helper.dart';

/// Represents my navigation item.
class MyNavigationItem {
  MyNavigationItem({
    required this.viewId,
    required this.label,
    required this.icon,
    required this.tooltip,
  });

  Icon icon;
  String label;
  String tooltip;

  /// The view this item opens.
  final ViewId viewId;

  /// Returns a stable key derived from the navigation label.
  Key get key => Key('key_menu_${label.toLowerCase()}');
}
