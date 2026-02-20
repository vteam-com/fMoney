import 'package:flutter/material.dart';

/// Represents my navigation item.
class MyNavigationItem {
  MyNavigationItem({
    required this.label,
    required this.icon,
    required this.tooltip,
  });

  Icon icon;
  String label;
  String tooltip;

  Key get key => Key('key_menu_${label.toLowerCase()}');
}
