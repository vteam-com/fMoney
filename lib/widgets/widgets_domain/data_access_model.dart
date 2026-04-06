import 'package:money/helpers/constants_helper.dart';
import 'package:money/widgets/pure/mutation_types.dart';
import 'package:money/widgets/widgets_domain/data_mutations_model.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/field_filters_model.dart';

typedef NotifyMutationChanged =
    void Function({
      required MutationType mutation,
      required DataObject moneyObject,
      bool recalculateBalances,
    });

typedef GetCategoryName = String Function(int id);
typedef GetCurrencyRatio = double Function(String symbol);

/// Represents data access.
class DataAccess {
  static late NotifyMutationChanged notifyMutationChanged;
  static late GetCategoryName getCategoryName;
  static late GetCurrencyRatio getCurrencyRatio;

  // breaking dependency with DataController
  static late DataMutations trackMutations;
  static late void Function() onDataChanged;
  static late void Function() onFileClosed;
  static late Future<String> Function() generateNextFolderToSaveTo;

  // breaking dependency between PreferenceController and DataController
  static late List<String> Function() getMRU;
  static late void Function(String) addToMRU;
  static late void Function({
    required ViewId viewId,
    required int selectedId,
    String textFilter,
    FieldFilters? columnFilters,
  })
  jumpToView;
  static late Future<void> Function() loadLastFileSaved;
}
