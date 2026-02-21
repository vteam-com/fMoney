// ignore_for_file: unnecessary_this
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/file_systems.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/views/data.dart';
import 'package:money/views/data_simulator.dart';
import 'package:money/views/merge_payee_provider.dart';
import 'package:money/views/money_data_io.dart';
import 'package:money/views/providers/account.dart';
import 'package:money/views/suggestion_approval_provider.dart';
import 'package:money/widgets/data_access.dart';
import 'package:money/widgets/data_mutations.dart';
import 'package:money/widgets/data_source.dart';
import 'package:money/widgets/pure/snack_bar.dart';
import 'package:path/path.dart' as p;

/// Controller for managing data file operations.
/// Features:
/// - Load/save files in multiple formats
/// - Track file state and modifications
/// - Manage MRU list
/// - File format conversions
/// - File location management
class DataFileController extends GetxController {
  DataFileController() {
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
  Rxn<DateTime> currentLoadedFileDateTime = Rxn<DateTime>();
  RxString currentLoadedFileName = Constants.untitledFileName.obs;
  RxList<String> data = <String>[].obs;
  String fileName = '';
  // Observable variables
  RxBool isLoading = true.obs;

  // Tracking changes
  DataMutations trackMutations = DataMutations();

  /// Closes the current data file and resets file state.
  void closeFile([bool rebuild = true]) {
    keepUnused(rebuild);
    Data().close();
    dataFileIsClosed();
    trackMutations.reset();
    isLoading.value = false;
  }

  /// Resets file state to untitled when file is closed.
  void dataFileIsClosed() {
    currentLoadedFileName.value = Constants.untitledFileName;
    currentLoadedFileDateTime.value = null;
  }

  /// Returns default folder path for saving files with given name.
  Future<String> defaultFolderToSaveTo(final String defaultFileName) async {
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

  /// Returns true if current file is untitled (no file loaded).
  bool get isUntitled => currentLoadedFileName.value == Constants.untitledFileName;

  /// Returns string representation of last update timestamp.
  String get lastUpdateAsString => '${trackMutations.lastDateTimeChanged}';

  /// Loads demo data for testing and demonstration purposes.
  Future<void> loadDemoData() async {
    isLoading.value = true;
    DataSimulator().generateData();
    Data().recalculateBalances();
    isLoading.value = false;
  }

  /// Loads data file from specified data source.
  Future<bool> loadFile(final DataSource dataSource) async {
    this.closeFile(false); // ensure that we closed current file and state

    try {
      final bool success = await MoneyDataIO().loadFromPath(Data(), dataSource);

      if (success) {
        setCurrentFileName(dataSource.filePath);
        currentLoadedFileDateTime.value = await MyFileSystems.getFileModifiedTime(
          dataSource.filePath,
        );
        Future<Null>.delayed(Duration.zero, () {
          Get.offNamed<dynamic>(Constants.routeHomePage);
        });
      }
      return success;
    } catch (e, stackTrace) {
      logger.e('Failed to load file: ${dataSource.filePath}', error: e, stackTrace: stackTrace);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Loads data file from specified data source path.
  Future<bool> loadFileFromPath(final DataSource dataSource) async {
    return await loadFile(dataSource);
  }

  /// Loads the last saved file from preferences.
  Future<void> loadLastFileSaved() async {
    try {
      isLoading.value = true;

      if (DataAccess.getMRU().isNotEmpty) {
        final bool loaded = await loadFile(DataSource(filePath: DataAccess.getMRU().first));
        if (!loaded) {
          Future<Null>.delayed(Duration.zero, () {
            Get.offNamed<dynamic>(Constants.routeWelcomePage);
          });
        }
        return;
      } else {
        // Once the file is loaded, navigate to the main screen
        isLoading.value = false;

        Future<Null>.delayed(Duration.zero, () {
          Get.offNamed<dynamic>(Constants.routeWelcomePage);
        });
      }
    } catch (e, stackTrace) {
      // Handle error
      logger.e('Error fetching data', error: e, stackTrace: stackTrace);
      isLoading.value = false;
      Future<Null>.delayed(Duration.zero, () {
        Get.offNamed<dynamic>(Constants.routeWelcomePage);
      });
    }
  }

  /// Creates a new untitled data file with default account.
  void onFileNew() async {
    this.closeFile();

    final Account newAccount = Data().accounts.addNewAccount(
      'New Bank Account',
    );
    DataAccess.jumpToView(
      viewId: ViewId.viewAccounts,
      selectedId: newAccount.uniqueId,
      textFilter: '',
      columnFilters: null,
    );
  }

  /// Opens file picker to select and load a data file.
  Future<bool> onFileOpen() async {
    FilePickerResult? pickerResult;

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
        pickerResult = await FilePicker.platform.pickFiles(type: FileType.any);
      } else
      // Mobile
      if (Platform.isAndroid || Platform.isIOS) {
        // See https://github.com/miguelpruivo/flutter_file_picker/issues/729
        pickerResult = await FilePicker.platform.pickFiles(type: FileType.any);
      } else
      // Desktop
      {
        pickerResult = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: supportedFileTypes,
        );
      }
    } catch (e) {
      logger.e(e.toString());
      SnackBarService.displayError(message: e.toString());
      return false;
    }

    if (pickerResult != null && pickerResult.files.isNotEmpty) {
      try {
        final String? fileExtension = pickerResult.files.single.extension;

        if (fileExtension == 'mmdb' || fileExtension == 'mmcsv') {
          late DataSource dataSource;
          if (kIsWeb) {
            final PlatformFile file = pickerResult.files.first;
            dataSource = DataSource(
              filePath: file.name,
              fileBytes: file.bytes!,
            );
          } else {
            dataSource = DataSource(
              filePath: pickerResult.files.single.path ?? '',
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
  void onSaveToCsv() async {
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
      onSaveCompleted: (final bool success, final String message) {
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
  void onShowFileLocation() async {
    final String path = await generateNextFolderToSaveTo();
    showLocalFolder(path);
  }

  /// Sets the current loaded file name and updates MRU list.
  void setCurrentFileName(final String filenameLoaded) {
    currentLoadedFileName.value = filenameLoaded;
    DataAccess.addToMRU(filenameLoaded);
  }

  /// Returns the singleton DataFileController instance.
  static DataFileController get to => Get.find();
}
