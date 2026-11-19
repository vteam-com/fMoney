import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/widgets/pure/theme_custom_model.dart';

/// The kinds of pending change shown to the user, in display order.
const List<MutationType> pendingMutationTypes = <MutationType>[
  MutationType.inserted,
  MutationType.changed,
  MutationType.deleted,
];

/// Colour, label and prefix that show a kind of pending change.
extension MutationTypeDisplay on MutationType {
  /// Returns the theme colour of this change in [context]; transparent for kinds that are not shown.
  Color getColor(BuildContext context) => switch (this) {
    MutationType.inserted => context.colorTheme.getColorForState(ColorState.success),
    MutationType.changed => context.colorTheme.getColorForState(ColorState.warning),
    MutationType.deleted => context.colorTheme.getColorForState(ColorState.error),
    _ => Colors.transparent,
  };

  /// Returns the translation key of this change's label; empty for kinds that are not shown.
  String get labelKey => switch (this) {
    MutationType.inserted => AppTranslationKeys.mutationAdded,
    MutationType.changed => AppTranslationKeys.mutationModified,
    MutationType.deleted => AppTranslationKeys.mutationDeleted,
    _ => '',
  };

  /// Returns the sign written before this change's count; empty for kinds that are not shown.
  String get prefix => switch (this) {
    MutationType.inserted => '+',
    MutationType.changed => '=',
    MutationType.deleted => '-',
    _ => '',
  };
}
