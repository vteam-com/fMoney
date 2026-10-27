import 'package:money/shared/presentation/entity_widgets/category_suggestion_provider_interface.dart';
import 'package:money/shared/presentation/entity_widgets/merge_payee_provider_interface.dart';

/// Presentation providers used by entity widgets, bound at startup by the data file controller.
class EntityWidgetProviders {
  /// Builds the category suggestion widget shown in transaction category cells.
  static CategorySuggestionProvider? categorySuggestion;

  /// Shows the merge-payee flow from the payee picker.
  static MergePayeeProvider? mergePayee;
}
