// ignore_for_file: unnecessary_this
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:money/core/controller/preferences_controller.dart';
import 'package:money/core/helpers/file_systems.dart';
import 'package:money/core/helpers/string_helper.dart';
import 'package:money/core/widgets/snack_bar.dart';
import 'package:money/data/models/money_objects/accounts/account.dart';
import 'package:money/data/storage/data/data.dart';
import 'package:money/data/storage/data/data_mutations.dart';
import 'package:money/data/storage/data/data_simulator.dart';
import 'package:path/path.dart' as p;

/// Controller for managing data file operations.
/// Features:
/// - Load/save files in multiple formats
/// - Track file state and modifications
/// - Manage MRU list
/// - File format conversions
/// - File location management
class DataController extends GetxController {
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
    return MyFileSystems.append(await getDocumentDirectory(), defaultFileName);
  }

  Future<String> generateNextFolderToSaveTo() async {
    if (currentLoadedFileName.value.isNotEmpty) {
      if (p.extension(currentLoadedFileName.value) == '.mmcsv' || p.extension(currentLoadedFileName.value) == '.mmdb') {
        return p.dirname(currentLoadedFileName.value);
      }
    }
    return await getDocumentDirectory();
  }

  bool get isUntitled => currentLoadedFileName.value == Constants.untitledFileName;

  String get lastUpdateAsString => '${trackMutations.lastDateTimeChanged}';

  Future<void> loadDemoData() async {
    isLoading.value = true;
    loadFromDemoData();
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

      if (PreferenceController.to.mru.isNotEmpty) {
        await loadFile(DataSource(filePath: PreferenceController.to.mru.first));
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
    PreferenceController.to.jumpToView(
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

    PreferenceController.to.addToMRU(fullPathToFileName);

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

    PreferenceController.to.addToMRU(fileNameAndPath);
    return result;
  }

  void onShowFileLocation() async {
    final String path = await generateNextFolderToSaveTo();
    showLocalFolder(path);
  }

  void setCurrentFileName(final String filenameLoaded) {
    currentLoadedFileName.value = filenameLoaded;
    final PreferenceController preferenceController = Get.find();
    preferenceController.addToMRU(filenameLoaded);
  }

  static DataController get to => Get.find();
}

/// Data source configuration for file loading operations.
/// Supports:
/// - Local file paths
/// - In-memory byte data
/// - File format validation
class DataSource {
  DataSource({this.filePath = '', Uint8List? fileBytes}) : _fileBytes = fileBytes ?? Uint8List(0);

  final String filePath;

  final Uint8List _fileBytes;

  Uint8List get fileBytes => _fileBytes;
}
