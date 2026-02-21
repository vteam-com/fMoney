// ignore: fcheck_dead_code
import 'package:get/get.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/widgets/data_access.dart';
import 'package:money/widgets/widgets_domain/field_filter.dart';
import 'package:money/widgets/widgets_domain/field_filters.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int _defaultCashflowRecurringOccurrences = 12;
const int _defaultNetWorthEventThreshold = 5;

/// Controller for managing application preferences and settings.
/// Handles:
/// - MRU (Most Recently Used) files
/// - View settings and filters
/// - Display options
/// - Feature flags
/// - Theme preferences
/// - Window state
/// - Font scaling
/// Uses SharedPreferences for persistence.
class PreferenceController extends GetxController {
  PreferenceController() {
    DataAccess.getMRU = () => mru;
    DataAccess.addToMRU = addToMRU;
    DataAccess.jumpToView = jumpToView;
  }
  final RxBool isReady = false.obs;
  final RxBool useYahooStock = true.obs;

  Rx<BudgetViewAs> budgetViewAsForExpenses = BudgetViewAs.list.obs;
  Rx<BudgetViewAs> budgetViewAsForIncomes = BudgetViewAs.list.obs;
  RxInt cashflowRecurringOccurrences = _defaultCashflowRecurringOccurrences.obs;
  Rx<CashflowViewAs> cashflowViewAs = CashflowViewAs.sankey.obs;

  ///---------------------------------
  /// Observable enum
  Rx<ViewId> currentView = ViewId.viewCashFlow.obs;

  RxList<String> mru = <String>[].obs;
  RxInt netWorthEventThreshold = _defaultNetWorthEventThreshold.obs;
  Rx<bool> trendIncludeAssetAccounts = false.obs;

  final RxString _apiKeyForStocks = ''.obs;
  final RxBool _includeClosedAccounts = false.obs;

  ///---------------------------------
  /// Include Rental feature
  final RxBool _includeRentalManagement = false.obs;

  ///---------------------------------
  /// SidePanel
  ///
  /// Expand/Collapse
  final RxBool _isSidePanelExpanded = false.obs;

  /// GET
  bool get isSidePanelExpanded => _isSidePanelExpanded.value;

  /// SET
  set isSidePanelExpanded(final bool value) {
    _isSidePanelExpanded.value = value;

    // persist
    setBool(settingKeySidePanelExpanded, value);
  }

  ///---------------------------------
  /// SidePanel Height
  ///
  /// Expand/Collapse
  final RxInt _sidePanelHeight = Constants.sidePanelHeightWhenExpanded.obs;

  /// GET
  int get sidePanelHeight => _sidePanelHeight.value;

  /// SET
  set sidePanelHeight(final int value) {
    _sidePanelHeight.value = value;

    // persist
    setInt(settingKeySidePanelHeight, value);
  }

  ///---------------------------------
  /// Selected SidePanel Tab
  final Rx<SidePanelSubViewEnum> _selectedSidePanelTabId = SidePanelSubViewEnum.details.obs;

  /// GET
  SidePanelSubViewEnum get selectedSidePanelTabId => _selectedSidePanelTabId.value;

  /// SET
  set selectedSidePanelTabId(SidePanelSubViewEnum value) {
    _selectedSidePanelTabId.value = value;
    // persist
    setInt(settingKeySelectedSidePanelTab, value.index);
  }

  // Side panel helper methods to reduce duplication
  /// Returns the side panel sort field preference key.
  int getSidePanelSortBy() => getInt('$settingKeySidePanel$settingKeySortBy', 0);

  /// Sets the side panel sort field preference value.
  void setSidePanelSortBy(int value) => setInt('$settingKeySidePanel$settingKeySortBy', value);

  /// Returns the side panel sort ascending preference.
  bool getSidePanelSortAscending() => getBool('$settingKeySidePanel$settingKeySortAscending', true);

  /// Sets the side panel sort ascending preference.
  void setSidePanelSortAscending(bool value) => setBool('$settingKeySidePanel$settingKeySortAscending', value);

  /// Returns the side panel selected item ID preference.
  int getSidePanelSelectedItemId() => getInt('$settingKeySidePanel$settingKeySelectedListItemId', -1);

  /// Sets the side panel selected item ID preference.
  void setSidePanelSelectedItemId(int value) => setInt('$settingKeySidePanel$settingKeySelectedListItemId', value);

  //////////////////////////////////////////////////////
  // Persistable user preference

  ///---------------------------------
  /// Text Font Size/Scale
  final RxDouble _textScale = 1.0.obs;

  SharedPreferences? _preferences;

  @override
  void onInit() async {
    super.onInit();
    await init();
    if (mru.isNotEmpty) {
      DataAccess.loadLastFileSaved();
    } else {
      // queue changing screen after app loaded
      Future<Null>.delayed(const Duration(milliseconds: 100), () {
        Get.offNamed<dynamic>(Constants.routeWelcomePage);
      });
    }
  }

  /// Adds an item to the MRU (most recently used) list.
  void addToMRU(final String filePathAndName) {
    if (filePathAndName.isNotEmpty) {
      // load and place on top
      mru.remove(filePathAndName);
      mru.insert(0, filePathAndName);

      // save it
      if (_preferences != null) {
        _preferences!.setStringList(settingKeyMRU, mru);
      }
    }
  }

  ///---------------------------------
  /// Stock quote API Key
  String get apiKeyForStocks => _apiKeyForStocks.value;

  ///---------------------------------
  set apiKeyForStocks(final String value) {
    _apiKeyForStocks.value = value;
    setString(settingKeyStockApiKey, value);
  }

  // Clear all values from preferences
  /// Clears all stored preference values.
  Future<void> clear() async {
    await _preferences?.clear();
  }

  // Retrieve a boolean value from preferences
  /// Returns a boolean value from preferences with optional default.
  bool getBool(String key, [bool defaultValueIfNotFound = false]) =>
      _preferences?.getBool(key) ?? defaultValueIfNotFound;

  // Retrieve a double value from preferences
  /// Returns a double value from preferences with optional default.
  double getDouble(String key, [double defaultValueIfNotFound = 0.0]) =>
      _preferences?.getDouble(key) ?? defaultValueIfNotFound;

  // Retrieve an integer value from preferences
  /// Returns an integer value from preferences with optional default.
  int getInt(String key, [int defaultValueIfNotFound = 0]) => _preferences?.getInt(key) ?? defaultValueIfNotFound;

  // Retrieve a string value from preferences
  /// Returns a string value from preferences with optional default.
  String getString(String key, [String defaultValueIfNotFound = '']) =>
      _preferences?.getString(key) ?? defaultValueIfNotFound;

  // Retrieve a list of strings from preferences
  /// Returns a string list from preferences with optional default.
  Future<List<String>> getStringList(String key) async => _preferences?.getStringList(key) ?? <String>[];

  /// Returns a unique state string combining key preference values.
  String get getUniqueState =>
      'isReady:${isReady.value} Rental:$includeRentalManagement IncludeClosedAccounts:$includeClosedAccounts TextScale:$textScale';

  ///---------------------------------
  /// Show or Hide Account that are marked as Closed
  /// Hide/Show Closed Accounts
  /// Returns whether closed accounts should be included in views.
  bool get includeClosedAccounts => _includeClosedAccounts.value;

  /// Sets whether closed accounts should be included in views.
  set includeClosedAccounts(bool value) {
    _includeClosedAccounts.value = value;
    setBool(settingKeyIncludeClosedAccounts, value);
  }

  ///--------------------------------
  /// Rental
  /// Returns whether rental management should be included in views.
  bool get includeRentalManagement => _includeRentalManagement.value;

  /// Sets whether rental management should be included in views.
  set includeRentalManagement(final bool value) {
    _includeRentalManagement.value = value;
    setBool(settingKeyRentalsSupport, value);
  }

  /// Initializes preferences and loads stored values.
  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    await loadDefaults();
    isReady.value = true;
  }

  /// Navigates to specified view with selected item ID.
  void jumpToView({
    required final ViewId viewId,
    required final int selectedId,
    final String textFilter = '',
    final FieldFilters? columnFilters,
  }) async {
    // First set all filters on the destination view
    await setString(
      viewId.getViewPreferenceId(settingKeyFilterText),
      textFilter,
    );
    if (columnFilters != null) {
      final String jsonString = columnFilters.toJsonString();
      await setString(
        viewId.getViewPreferenceId(settingKeyFiltersColumns),
        jsonString,
      );
    }

    // Set the last selected item, in order to have it selected when the view changes
    if (selectedId != -1) {
      await setInt(
        viewId.getViewPreferenceId(settingKeySelectedListItemId),
        selectedId,
      );
    }

    // Change to the requested view
    setView(viewId);
  }

  /// Loads default preference values when none are set.
  Future<void> loadDefaults() async {
    mru.value = _preferences!.getStringList(settingKeyMRU) ?? <String>[];

    // Side Panel Expanded/Collapsed
    _isSidePanelExpanded.value = getBool(settingKeySidePanelExpanded, false);

    // Side Panel Height
    _sidePanelHeight.value = getInt(
      settingKeySidePanelHeight,
      isSidePanelExpanded ? Constants.sidePanelHeightWhenExpanded : Constants.sidePanelHeightWhenCollapsed,
    );

    _includeClosedAccounts.value = getBool(
      settingKeyIncludeClosedAccounts,
      false,
    );
    _includeRentalManagement.value = getBool(settingKeyRentalsSupport, false);
    _apiKeyForStocks.value = getString(settingKeyStockApiKey, '');

    cashflowViewAs.value =
        CashflowViewAs.values[getInt(
          settingKeyCashflowView,
          CashflowViewAs.sankey.index,
        )];
    budgetViewAsForIncomes.value =
        BudgetViewAs.values[getInt(
          settingKeyBudgetViewAsIncomes,
          BudgetViewAs.list.index,
        )];
    budgetViewAsForExpenses.value =
        BudgetViewAs.values[getInt(
          settingKeyBudgetViewAsExpenses,
          BudgetViewAs.list.index,
        )];
    cashflowRecurringOccurrences.value = getInt(
      settingKeyCashflowRecurringOccurrences,
      _defaultCashflowRecurringOccurrences,
    );
  }

  // Remove a value from preferences
  /// Removes a preference value by key.
  Future<void> remove(String key) async {
    await _preferences?.remove(key);
  }

  // Set a boolean value to preferences
  /// Sets a boolean preference value by key.
  Future<void> setBool(String key, bool value) async {
    await _preferences?.setBool(key, value);
  }

  // Set a double value to preferences
  /// Sets a double preference value by key.
  Future<void> setDouble(String key, double value) async {
    await _preferences?.setDouble(key, value);
  }

  // Set an integer value to preferences
  /// Sets an integer preference value by key.
  Future<void> setInt(String key, int value) async {
    await _preferences?.setInt(key, value);
  }

  /// Sets a raw JSON string preference value by key.
  Future<void> setMyJson(String key, String value) async {
    await _preferences?.setString(key, value);
  }

  /// Sets a JSON map preference value by key.
  Future<void> setMapOfMyJson(String key, Map<String, dynamic> value) async {
    await _preferences?.setString(key, json.encode(value));
  }

  // Set a string value to preferences
  /// Sets a string preference value by key.
  Future<void> setString(
    String key,
    String value, [
    bool removeIfEmpty = false,
  ]) async {
    if (removeIfEmpty && value.isEmpty) {
      await remove(key);
    } else {
      await _preferences?.setString(key, value);
    }
  }

  // Set a list of strings to preferences
  /// Sets a string list preference value by key.
  Future<void> setStringList(String key, List<String> value) async {
    if (value.isEmpty) {
      remove(key);
    } else {
      await _preferences?.setStringList(key, value);
    }
  }

  // Methods to update the current view
  /// Updates the current view to the specified ViewId.
  void setView(ViewId view) {
    currentView.value = view;
  }

  /// Returns the current text scale factor.
  double get textScale => _textScale.value;

  /// Sets the text scale factor and saves to preferences.
  set textScale(double value) {
    _textScale.value = value;
    setDouble(settingKeyTextScale, textScale);
  }

  /// Returns the singleton PreferenceController instance.
  static PreferenceController get to => Get.find();
}

/// Navigation helpers

void switchViewTransactionForPayee(final String payeeName) async {
  final FieldFilters fieldFilters = FieldFilters();
  fieldFilters.add(
    FieldFilter(
      fieldName: Constants.viewTransactionFieldNamePayee,
      strings: <String>[payeeName],
    ),
  );

  await PreferenceController.to.setString(
    ViewId.viewTransactions.getViewPreferenceId(settingKeyFiltersColumns),
    fieldFilters.toJsonString(),
  );

  // Switch view
  PreferenceController.to.setView(ViewId.viewTransactions);
}
