import 'package:money/data/storage/data/data_mutations.dart';
import 'package:money/widgets/fields/field_filters.dart';
import 'package:money/widgets/fields/money_object.dart';

typedef NotifyMutationChanged =
    void Function({
      required MutationType mutation,
      required MoneyObject moneyObject,
      bool recalculateBalances,
    });

typedef GetCategoryName = String Function(int id);
typedef GetCurrencyRatio = double Function(String symbol);

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
