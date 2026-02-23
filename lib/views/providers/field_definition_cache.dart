import 'package:money/widgets/widgets_domain/field.dart';

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
