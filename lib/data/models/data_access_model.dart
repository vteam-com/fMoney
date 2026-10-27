import 'package:money/data/models/data_mutations_model.dart';
import 'package:money/data/models/field_filters_model.dart';
import 'package:money/helpers/constants_helper.dart';

/// Represents data access.
class DataAccess {
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
