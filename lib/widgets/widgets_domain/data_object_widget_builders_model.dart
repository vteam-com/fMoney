import 'package:flutter/widgets.dart';
import 'package:money/data/models/data_object_model.dart';
import 'package:money/data/models/field_model.dart';

/// Returns an entity-specific display widget for [field] of [instance], or null to use the generic one.
typedef FieldWidgetOverrideBuilder = Widget? Function(DataObject instance, Field<dynamic> field);

/// Returns an entity-specific editor for [field] of [instance], or null to use the generic one.
typedef FieldEditWidgetOverrideBuilder = Widget? Function(
  DataObject instance,
  Field<dynamic> field,
  void Function(bool wasModified) onEdited,
);

/// Builds the compact small-screen card for [instance].
typedef SmallScreenWidgetBuilder = Widget Function(DataObject instance);

/// Entity-specific widget builders supplied by the presentation layer to generic list and detail widgets.
class DataObjectWidgetBuilders {
  /// Creates the builder bundle used by list rows, detail panels and small-screen cards.
  const DataObjectWidgetBuilders({
    required this.buildFieldWidget,
    required this.buildEditWidget,
    required this.buildSmallScreen,
  });

  /// Builds an entity-specific display widget, or null for the generic rendering.
  final FieldWidgetOverrideBuilder buildFieldWidget;

  /// Builds an entity-specific editor, or null for the generic editor.
  final FieldEditWidgetOverrideBuilder buildEditWidget;

  /// Builds one small-screen card.
  final SmallScreenWidgetBuilder buildSmallScreen;
}
