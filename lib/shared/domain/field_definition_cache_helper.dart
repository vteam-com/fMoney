import 'package:money/widgets/widgets_domain/field_model.dart';

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

  /// Includes this field in [fields] when true.
  final bool includeInEntity;

  /// Includes this field in [fieldsForColumnView] when true.
  final bool includeInColumnView;
}

/// Initializes [cache] once using [instanceFactory] and [definitionsBuilder], then returns it.
Fields<T> ensureCachedFieldDefinitions<T>({
  required Fields<T> cache,
  required T Function() instanceFactory,
  required FieldDefinitions Function(T _) definitionsBuilder,
}) {
  if (cache.isEmpty) {
    cache.setDefinitions(definitionsBuilder(instanceFactory()));
  }
  return cache;
}

/// Initializes [cache] from [blueprints] once, filtering by [forColumnView].
Fields<T> ensureCachedFieldDefinitionsFromBlueprints<T>({
  required Fields<T> cache,
  required T Function() instanceFactory,
  required List<FieldBlueprint<T>> blueprints,
  required bool forColumnView,
}) {
  if (cache.isEmpty) {
    final T instance = instanceFactory();
    final FieldDefinitions definitions = blueprints
        .where(
          (FieldBlueprint<T> blueprint) => forColumnView ? blueprint.includeInColumnView : blueprint.includeInEntity,
        )
        .map((FieldBlueprint<T> blueprint) => blueprint.selector(instance))
        .toList();
    cache.setDefinitions(definitions);
  }
  return cache;
}
