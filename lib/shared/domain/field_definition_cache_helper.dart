import 'package:money/data/models/data_interface.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/shared/domain/field_blueprint_model.dart';

export 'package:money/shared/domain/field_blueprint_model.dart';

/// The field definitions of an entity type [T], built once from its [blueprints]: those of the
/// entity itself and those of its column view.
class FieldDefinitionCache<T> {
  /// Declares the [blueprints] of [T], read from the template instance [instanceFactory] creates.
  FieldDefinitionCache({required this.instanceFactory, required this.blueprints});

  /// The fields of [T] in display order, each with the definitions it belongs to.
  final List<FieldBlueprint<T>> blueprints;

  /// Creates the template instance whose fields become the shared definitions.
  final T Function() instanceFactory;

  final Fields<T> _fields = Fields<T>();
  final Fields<T> _fieldsForColumnView = Fields<T>();

  /// Returns the definitions of the blueprints included in the entity.
  Fields<T> get fields => _ensureBuilt(_fields, forColumnView: false);

  /// Returns the definitions of the blueprints included in the column view.
  Fields<T> get fieldsForColumnView => _ensureBuilt(_fieldsForColumnView, forColumnView: true);

  /// Fills [cache] once with the blueprints selected by [forColumnView], then returns it.
  ///
  /// Each definition is bound to its row through its blueprint selector, see [Field.bindToRows].
  Fields<T> _ensureBuilt(Fields<T> cache, {required bool forColumnView}) {
    if (cache.isEmpty) {
      final T instance = instanceFactory();
      final FieldDefinitions definitions = blueprints
          .where(
            (FieldBlueprint<T> blueprint) => forColumnView ? blueprint.includeInColumnView : blueprint.includeInEntity,
          )
          .map(
            (FieldBlueprint<T> blueprint) =>
                blueprint.selector(instance)..bindToRows((DataInterface row) => blueprint.selector(row as T)),
          )
          .toList();
      cache.setDefinitions(definitions);
    }
    return cache;
  }
}
