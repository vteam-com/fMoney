// ignore_for_file: unnecessary_this
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/file_systems_service.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/presentation/providers/merge_payee_provider.dart';
import 'package:money/shared/presentation/providers/suggestion_approval_provider.dart';
import 'package:money/shared/presentation/services/money_data_io_service.dart';
import 'package:money/shared/simulation/data_simulator_service.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';
import 'package:money/widgets/widgets_domain/data_access_model.dart';
import 'package:money/widgets/widgets_domain/data_mutations_model.dart';
import 'package:money/widgets/widgets_domain/data_source_model.dart';
import 'package:path/path.dart' as p;

/// Controller for managing data file operations.
/// Features:
/// - Load/save files in multiple formats
/// - Track file state and modifications
/// - Manage MRU list
/// - File format conversions
/// - File location management
class DataFileController extends ChangeNotifier {
  DataFileController() {
    DataFileController.instance = this;
    DataAccess.trackMutations = trackMutations;
    DataAccess.onDataChanged = update;
    DataAccess.onFileClosed = dataFileIsClosed;
    DataAccess.generateNextFolderToSaveTo = generateNextFolderToSaveTo;
    DataAccess.loadLastFileSaved = loadLastFileSaved;

    // Bind the category suggestion provider
    Data().categorySuggestionProvider = SuggestionApprovalProvider();

    // Bind the merge payee provider
    Data().mergePayeeProvider = DefaultMergePayeeProvider();
  }
  final ValueNotifier<DateTime?> currentLoadedFileDateTime = ValueNotifier<DateTime?>(null);
  final ValueNotifier<String> currentLoadedFileName = ValueNotifier<String>(Constants.untitledFileName);
  final ValueNotifier<List<String>> data = ValueNotifier<List<String>>(<String>[]);
  String fileName = '';
  // Observable variables
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(true);

  // Tracking changes
  final DataMutations trackMutations = DataMutations();

  /// Global access to the live app data file controller.
  static DataFileController? instance;

  /// Notifies listeners that the underlying data model has changed.
  void update() {
    notifyListeners();
  }

  /// Closes the current data file and resets file state.
  void closeFile([bool rebuild = true]) {
    keepUnused(rebuild);
    Data().close();
    dataFileIsClosed();
    trackMutations.reset();
    isLoading.value = false;
    notifyListeners();
  }

  /// Resets file state to untitled when file is closed.
  void dataFileIsClosed() {
    currentLoadedFileName.value = Constants.untitledFileName;
    currentLoadedFileDateTime.value = null;
    notifyListeners();
  }

  /// Returns default folder path for saving files with given name.
  Future<String> defaultFolderToSaveTo(String defaultFileName) async {
    return MyFileSystems.append('.', defaultFileName);
  }

  /// Generates next folder path for saving based on current file location.
  Future<String> generateNextFolderToSaveTo() async {
    if (currentLoadedFileName.value.isNotEmpty && currentLoadedFileName.value != Constants.untitledFileName) {
      final String extension = p.extension(currentLoadedFileName.value);
      if (extension == '.mmcsv' || extension == '.mmdb') {
        return p.dirname(currentLoadedFileName.value);
      }
    }
    return '.';
  }

  /// Returns string representation of last update timestamp.
  String get lastUpdateAsString => '${trackMutations.lastDateTimeChanged}';

  /// Loads demo data for testing and demonstration purposes.
  Future<void> loadDemoData() async {
    isLoading.value = true;
    notifyListeners();
    DataSimulator().generateData();
    Data().recalculateBalances();
    isLoading.value = false;
    notifyListeners();
  }

  /// Loads data file from specified data source.
  Future<bool> loadFile(DataSource dataSource) async {
    this.closeFile(false); // ensure that we closed current file and state

    try {
      final bool success = await MoneyDataIO().loadFromPath(Data(), dataSource);

      if (success) {
        setCurrentFileName(dataSource.filePath);
        currentLoadedFileDateTime.value = await MyFileSystems.getFileModifiedTime(
          dataSource.filePath,
        );
        notifyListeners();
        SchedulerBinding.instance.addPostFrameCallback((Duration _) {
          AppRouter.pushReplacementNamed<dynamic, dynamic>(Constants.routeHomePage);
        });
      }
      return success;
    } catch (e, stackTrace) {
      logger.e('Failed to load file: ${dataSource.filePath}', error: e, stackTrace: stackTrace);
      return false;
    } finally {
      isLoading.value = false;
      notifyListeners();
    }
  }

  /// Loads data file from specified data source path.
  Future<bool> loadFileFromPath(DataSource dataSource) async {
    return await loadFile(dataSource);
  }

  /// Loads the last saved file from preferences.
  Future<void> loadLastFileSaved() async {
    try {
      isLoading.value = true;
      notifyListeners();

      if (DataAccess.getMRU().isNotEmpty) {
        final bool loaded = await loadFile(DataSource(filePath: DataAccess.getMRU().first));
        if (!loaded) {
          SchedulerBinding.instance.addPostFrameCallback((Duration _) {
            AppRouter.pushReplacementNamed<dynamic, dynamic>(Constants.routeWelcomePage);
          });
        }
        return;
      } else {
        // Once the file is loaded, navigate to the main screen
        isLoading.value = false;
        notifyListeners();

        SchedulerBinding.instance.addPostFrameCallback((Duration _) {
          AppRouter.pushReplacementNamed<dynamic, dynamic>(Constants.routeWelcomePage);
        });
      }
    } catch (e, stackTrace) {
      // Handle error
      logger.e('Error fetching data', error: e, stackTrace: stackTrace);
      isLoading.value = false;
      notifyListeners();
      SchedulerBinding.instance.addPostFrameCallback((Duration _) {
        AppRouter.pushReplacementNamed<dynamic, dynamic>(Constants.routeWelcomePage);
      });
    }
  }

  /// Creates a new untitled data file with default account and navigates to the accounts view.
  Future<void> onFileNew() {
    this.closeFile();

    final Account newAccount = Data().accounts.addNewAccount(
      AppL10n.tr(AppTranslationKeys.newBankAccount),
    );
    DataAccess.jumpToView(
      viewId: ViewId.viewAccounts,
      selectedId: newAccount.uniqueId,
      textFilter: '',
      columnFilters: null,
    );
    return Future<void>.value();
  }

  /// Opens file picker to select and load a data file.
  Future<bool> onFileOpen() async {
    PlatformFile? pickedFile;

    const List<String> supportedFileTypes = <String>[
      'mmdb',
      'mmcsv',
      'sdf',
      'qfx',
      'ofx',
      'json',
    ];

    try {
      // WEB
      if (kIsWeb) {
        pickedFile = await FilePicker.pickFile(type: FileType.any);
      } else
      // Mobile
      if (Platform.isAndroid || Platform.isIOS) {
        // See https://github.com/miguelpruivo/flutter_file_picker/issues/729
        pickedFile = await FilePicker.pickFile(type: FileType.any);
      } else
      // Desktop
      {
        pickedFile = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: supportedFileTypes,
        );
      }
    } catch (e) {
      logger.e(e.toString());
      SnackBarService.displayError(message: e.toString());
      return false;
    }

    if (pickedFile != null) {
      try {
        final String fileExtension = p
            .extension(pickedFile.name)
            .replaceFirst('.', '')
            .toLowerCase();

        if (fileExtension == 'mmdb' || fileExtension == 'mmcsv') {
          late DataSource dataSource;
          if (kIsWeb) {
            dataSource = DataSource(
              filePath: pickedFile.name,
              fileBytes: await pickedFile.readAsBytes(),
            );
          } else {
            dataSource = DataSource(
              filePath: pickedFile.path ?? '',
            );
          }

          await loadFile(dataSource);
          return true;
        }
      } catch (e) {
        logger.e(e.toString());
        SnackBarService.displayError(message: e.toString());
      }
    }
    return false;
  }

  /// Saves current data to CSV file format.
  Future<void> onSaveToCsv() async {
    final String fullPathToFileName = await MoneyDataIO().saveToCsv(Data());

    setCurrentFileName(fullPathToFileName);

    trackMutations.reset();
  }

  /// Saves current data to SQL database file format.
  Future<bool> onSaveToSql() async {
    String fileNameAndPath = currentLoadedFileName.value;

    if (fileNameAndPath.isEmpty) {
      // this happens if the user started with a new file and click save to SQL
      fileNameAndPath = await defaultFolderToSaveTo('mymoney.mmdb');
    }

    final bool result = await MoneyDataIO().saveToSql(
      Data(),
      filePath: fileNameAndPath,
      onSaveCompleted: (bool success, String message) {
        if (success) {
          trackMutations.reset();
        } else {
          SnackBarService.displayError(autoDismiss: false, message: message);
        }
      },
    );

    DataAccess.addToMRU(fileNameAndPath);
    return result;
  }

  /// Shows the current file location in system file manager.
  Future<void> onShowFileLocation() async {
    // if (isPlatformMobile()) {
    //   SnackBarService.displayInfo(
    //     message: AppL10n.tr(AppTranslationKeys.fileLocationNotSupportedOnMobile),
    //   );
    //   return;
    // }
    final String path = await generateNextFolderToSaveTo();
    showLocalFolder(path);
  }

  /// Sets the current loaded file name and updates MRU list.
  void setCurrentFileName(String filenameLoaded) {
    currentLoadedFileName.value = filenameLoaded;
    DataAccess.addToMRU(filenameLoaded);
    notifyListeners();
  }

  /// Returns the singleton DataFileController instance.
  static DataFileController get to => instance ??= DataFileController();
}
