// ignore_for_file: unnecessary_this
import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:money/data/models/data_access_model.dart';
import 'package:money/data/models/data_mutations_model.dart';
import 'package:money/data/models/data_source_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/file_systems_service.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/page_unload_guard_helper.dart'
    if (dart.library.html) 'package:money/helpers/page_unload_guard_web_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/helpers/window_manager_service.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/presentation/entity_widgets/entity_widget_providers_model.dart';
import 'package:money/shared/presentation/providers/merge_payee_provider.dart';
import 'package:money/shared/presentation/providers/suggestion_approval_provider.dart';
import 'package:money/shared/presentation/services/money_data_io_service.dart';
import 'package:money/shared/simulation/data_simulator_service.dart';
import 'package:money/widgets/dialogs/unsaved_changes_dialog.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
    // Ask before quitting with unsaved changes
    MyWindowManager.confirmClose = confirmUnsavedChanges;
    installPageUnloadGuard(() => trackMutations.isMutated());
    DataAccess.loadLastFileSaved = loadLastFileSaved;

    // Bind the category suggestion provider
    EntityWidgetProviders.categorySuggestion = SuggestionApprovalProvider();

    // Bind the merge payee provider
    EntityWidgetProviders.mergePayee = DefaultMergePayeeProvider();

    // Account lists follow the user's "include closed accounts" preference
    Data().accounts.isIncludingClosedAccounts = () => PreferenceController.to.includeClosedAccounts;

    // Warn the user about transfers that lost their counterpart
    Data().onDanglingTransfersFound = _warnAboutDanglingTransfers;
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

  /// True when the current data came from (or was saved to) a real file, not a new "Untitled" one.
  bool get hasRealFilePath =>
      currentLoadedFileName.value.isNotEmpty && currentLoadedFileName.value != Constants.untitledFileName;

  /// Generates next folder path for saving based on current file location.
  Future<String> generateNextFolderToSaveTo() async {
    if (hasRealFilePath) {
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

  /// Loads data file from specified data source path (recent files), after asking about unsaved changes.
  Future<bool> loadFileFromPath(DataSource dataSource) async {
    if (!await confirmUnsavedChanges()) {
      return false;
    }
    return await loadFile(dataSource);
  }

  /// Closes the current file after asking about unsaved changes; returns false if the user cancelled.
  Future<bool> onFileClose() async {
    if (!await confirmUnsavedChanges()) {
      return false;
    }
    closeFile();
    return true;
  }

  /// Returns true when the in-memory data can be dropped: nothing is unsaved,
  /// or the user saved it or chose to discard it.
  Future<bool> confirmUnsavedChanges() async {
    if (!trackMutations.isMutated()) {
      return true;
    }
    final BuildContext? context = AppRouter.context;
    if (context == null) {
      return false;
    }
    switch (await showUnsavedChangesDialog(context, trackMutations.numberOfChanges())) {
      case UnsavedChangesChoice.save:
        return onSaveToSql();
      case UnsavedChangesChoice.discard:
        return true;
      case UnsavedChangesChoice.cancel:
        return false;
    }
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
  ///
  /// Returns false when the user chose to keep the current file (unsaved changes, Cancel).
  Future<bool> onFileNew() async {
    if (!await confirmUnsavedChanges()) {
      return false;
    }
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
    return true;
  }

  /// Opens file picker to select and load a data file.
  Future<bool> onFileOpen() async {
    if (!await confirmUnsavedChanges()) {
      return false;
    }
    PlatformFile? pickedFile;

    const List<String> supportedFileTypes = <String>[
      'mmdb',
      'mmcsv',
      'sdf',
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
        final String fileExtension = p.extension(pickedFile.name).replaceFirst('.', '').toLowerCase();

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

          // a file that failed to load must not open as an empty "Untitled" file
          return await loadFile(dataSource);
        }
      } catch (e) {
        logger.e(e.toString());
        SnackBarService.displayError(message: e.toString());
      }
    }
    return false;
  }

  /// Exports the data as a CSV archive to a location the user picks.
  ///
  /// This is an export: the current file and its pending changes are unchanged, unless the user
  /// saved over the very archive that is currently open.
  Future<bool> onSaveToCsv() async {
    final String? savedPath = await _saveBytesWithDialog(
      bytes: Uint8List.fromList(MoneyDataIO().getCsvZipAchieveListOfInt(Data())),
      extension: SharedStrings.fileExtensionMmcsv,
    );
    if (savedPath == null) {
      return false;
    }
    if (savedPath == currentLoadedFileName.value) {
      MoneyDataIO().markAllSaved(Data());
      trackMutations.reset();
      currentLoadedFileDateTime.value = await MyFileSystems.getFileModifiedTime(savedPath);
    }
    return true;
  }

  /// Saves the pending changes into the open .mmdb file.
  ///
  /// New files, archives (.mmcsv) and copies that cannot be written back go through [onSaveAs].
  /// Refuses (and suggests Save As) when the file vanished or another app changed it since it was opened.
  Future<bool> onSaveToSql() async {
    final String fileNameAndPath = currentLoadedFileName.value;
    if (!_canSaveInPlace(fileNameAndPath)) {
      return onSaveAs();
    }

    if (!File(fileNameAndPath).existsSync()) {
      SnackBarService.displayError(
        autoDismiss: false,
        message: AppL10n.tr(
          AppTranslationKeys.fileNoLongerExists,
          params: <String, String>{'fileName': fileNameAndPath},
        ),
      );
      return false;
    }
    final DateTime? modifiedOnDisk = await MyFileSystems.getFileModifiedTime(fileNameAndPath);
    if (currentLoadedFileDateTime.value != null && modifiedOnDisk != currentLoadedFileDateTime.value) {
      SnackBarService.displayError(
        autoDismiss: false,
        message: AppL10n.tr(
          AppTranslationKeys.fileChangedOnDisk,
          params: <String, String>{'fileName': fileNameAndPath},
        ),
      );
      return false;
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
    if (result) {
      currentLoadedFileDateTime.value = await MyFileSystems.getFileModifiedTime(fileNameAndPath);
      notifyListeners();
    }
    return result;
  }

  /// Writes all the data as a new .mmdb file at a location the user picks, which becomes the open file.
  Future<bool> onSaveAs() async {
    final Directory temporaryFolder = await getTemporaryDirectory();
    final String temporaryPath = p.join(
      temporaryFolder.path,
      'fmoney_${DateTime.now().millisecondsSinceEpoch}${SharedStrings.fileExtensionMmdb}',
    );
    final String? errorMessage = await MoneyDataIO().writeAllToNewSqlFile(Data(), filePath: temporaryPath);
    if (errorMessage != null) {
      SnackBarService.displayError(autoDismiss: false, message: errorMessage);
      return false;
    }
    final File temporaryFile = File(temporaryPath);
    final Uint8List bytes = temporaryFile.readAsBytesSync();
    temporaryFile.deleteSync();

    final String? savedPath = await _saveBytesWithDialog(bytes: bytes, extension: SharedStrings.fileExtensionMmdb);
    if (savedPath == null) {
      // cancelled: nothing was saved, every change is still pending
      return false;
    }
    MoneyDataIO().markAllSaved(Data());
    trackMutations.reset();
    if (savedPath.isNotEmpty) {
      setCurrentFileName(savedPath);
      currentLoadedFileDateTime.value = await MyFileSystems.getFileModifiedTime(savedPath);
    }
    return true;
  }

  /// True when [filePath] is an .mmdb file on this computer that can be updated in place.
  ///
  /// On mobile the opened file is a cache copy the OS may purge, so it is never updated in place.
  bool _canSaveInPlace(String filePath) {
    return hasRealFilePath &&
        !isPlatformMobile() &&
        p.extension(filePath).toLowerCase() == SharedStrings.fileExtensionMmdb;
  }

  /// Lets the user pick where to save [bytes]; returns the saved file path, '' when the platform
  /// saved it somewhere without a file path (e.g. a mobile document provider), or null if cancelled.
  /// [extension] includes the leading dot.
  Future<String?> _saveBytesWithDialog({required Uint8List bytes, required String extension}) async {
    final String suggestedName = hasRealFilePath
        ? '${p.basenameWithoutExtension(currentLoadedFileName.value)}$extension'
        : 'mymoney$extension';
    try {
      final Uri? savedUri = await FilePicker.saveFile(
        fileName: suggestedName,
        bytes: bytes,
        dialogTitle: AppL10n.tr(AppTranslationKeys.saveAs),
        initialDirectory: hasRealFilePath ? p.dirname(currentLoadedFileName.value) : null,
      );
      if (savedUri == null) {
        return null;
      }
      return savedUri.isScheme(SharedStrings.uriSchemeFile) ? savedUri.toFilePath() : '';
    } catch (e) {
      SnackBarService.displayError(autoDismiss: false, message: e.toString());
      return null;
    }
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

  /// Shows a non-dismissing warning listing how many transfers are dangling.
  void _warnAboutDanglingTransfers(int danglingCount) {
    Timer(
      const Duration(milliseconds: DurationInMs.quick),
      () => SnackBarService.displayWarning(
        message: '$danglingCount${SharedDomainStrings.domainString001}',
        title: SharedDomainStrings.domainString043,
        autoDismiss: false,
      ),
    );
  }
}
