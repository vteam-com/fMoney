import 'package:money/data/models/field_model.dart';

/// Selects a [Field] from a lightweight model instance.
typedef FieldSelector<T> = Field<dynamic> Function(T instance);

/// Declares how a model field participates in entity and column definitions.
class FieldBlueprint<T> {
  /// Creates a field blueprint with inclusion flags for entity and column views.
  const FieldBlueprint({
    required this.selector,
    this.includeInEntity = true,
    this.includeInColumnView = false,
  });

  /// Returns the field from a temporary model instance.
  final FieldSelector<T> selector;

  /// Includes this field in the entity field definitions when true.
  final bool includeInEntity;

  /// Includes this field in the column view field definitions when true.
  final bool includeInColumnView;
}
