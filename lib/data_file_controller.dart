// ignore_for_file: unnecessary_this
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:money/data/data.dart';
import 'package:money/data/data_simulator.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/file_systems.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/models/account.dart';
import 'package:money/suggestion_approval_provider.dart';
import 'package:money/widgets/data_access.dart';
import 'package:money/widgets/data_mutations.dart';
import 'package:money/widgets/data_source.dart';
import 'package:money/widgets/snack_bar.dart';
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
  }
  Rxn<DateTime> currentLoadedFileDateTime = Rxn<DateTime>();
  RxString currentLoadedFileName = Constants.untitledFileName.obs;
  RxList<String> data = <String>[].obs;
  String fileName = '';
  // Observable variables
  RxBool isLoading = true.obs;

  // Tracking changes
  DataMutations trackMutations = DataMutations();

  void closeFile([bool rebuild = true]) {
    Data().close();
    dataFileIsClosed();
    trackMutations.reset();
    isLoading.value = false;
  }

  void dataFileIsClosed() {
    currentLoadedFileName.value = Constants.untitledFileName;
    currentLoadedFileDateTime.value = null;
  }

  Future<String> defaultFolderToSaveTo(final String defaultFileName) async {
    return MyFileSystems.append('.', defaultFileName);
  }

  Future<String> generateNextFolderToSaveTo() async {
    if (currentLoadedFileName.value.isNotEmpty && currentLoadedFileName.value != Constants.untitledFileName) {
      final String extension = p.extension(currentLoadedFileName.value);
      if (extension == '.mmcsv' || extension == '.mmdb') {
        return p.dirname(currentLoadedFileName.value);
      }
    }
    return '.';
  }

  bool get isUntitled => currentLoadedFileName.value == Constants.untitledFileName;

  String get lastUpdateAsString => '${trackMutations.lastDateTimeChanged}';

  Future<void> loadDemoData() async {
    isLoading.value = true;
    DataSimulator().generateData();
    Data().recalculateBalances();
    isLoading.value = false;
  }

  Future<bool> loadFile(final DataSource dataSource) async {
    this.closeFile(false); // ensure that we closed current file and state

    final bool success = await Data().loadFromPath(dataSource);

    if (success) {
      setCurrentFileName(dataSource.filePath);
      currentLoadedFileDateTime.value = await MyFileSystems.getFileModifiedTime(
        dataSource.filePath,
      );
      Future<Null>.delayed(Duration.zero, () {
        Get.offNamed<dynamic>(Constants.routeHomePage);
      });
    }
    isLoading.value = false;
    return success;
  }

  Future<bool> loadFileFromPath(final DataSource dataSource) async {
    return await loadFile(dataSource);
  }

  // Async method to fetch data
  Future<void> loadLastFileSaved() async {
    try {
      isLoading.value = true;

      if (DataAccess.getMRU().isNotEmpty) {
        await loadFile(DataSource(filePath: DataAccess.getMRU().first));
        return;
      } else {
        // Once the file is loaded, navigate to the main screen
        isLoading.value = false;

        Future<Null>.delayed(Duration.zero, () {
          Get.offNamed<dynamic>(Constants.routeWelcomePage);
        });
      }
    } catch (e) {
      // Handle error
      logger.e('Error fetching data: $e');
    }
  }

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

  void onSaveToCsv() async {
    final String fullPathToFileName = await Data().saveToCsv();

    setCurrentFileName(fullPathToFileName);

    trackMutations.reset();
  }

  Future<bool> onSaveToSql() async {
    String fileNameAndPath = currentLoadedFileName.value;

    if (fileNameAndPath.isEmpty) {
      // this happens if the user started with a new file and click save to SQL
      fileNameAndPath = await defaultFolderToSaveTo('mymoney.mmdb');
    }

    final bool result = await Data().saveToSql(
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

  void onShowFileLocation() async {
    final String path = await generateNextFolderToSaveTo();
    showLocalFolder(path);
  }

  void setCurrentFileName(final String filenameLoaded) {
    currentLoadedFileName.value = filenameLoaded;
    DataAccess.addToMRU(filenameLoaded);
  }

  static DataFileController get to => Get.find();
}
