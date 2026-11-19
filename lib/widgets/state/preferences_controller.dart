// ignore: fcheck_dead_code
import 'package:flutter/widgets.dart';
import 'package:money/data/models/data_access_model.dart';
import 'package:money/data/models/field_filters_model.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int _defaultCashflowRecurringOccurrences = 12;
const int _defaultNetWorthEventThreshold = 5;

/// Preference key of [PreferenceController.netWorthEventThreshold].
const String _settingKeyNetWorthEventThreshold = 'keyNetWorthEventThreshold';
const String _settingKeyTrendIncludeAssetAccounts = 'keyTrendIncludeAssetAccounts';

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
class PreferenceController extends ChangeNotifier {
  PreferenceController() {
    PreferenceController.instance = this;
    DataAccess.getMRU = () => mru;
    DataAccess.addToMRU = addToMRU;
    DataAccess.jumpToView = jumpToView;
  }
  bool isReady = false;
  bool useYahooStock = true;

  BudgetViewAs budgetViewAsForExpenses = BudgetViewAs.list;
  BudgetViewAs budgetViewAsForIncomes = BudgetViewAs.list;
  int cashflowRecurringOccurrences = _defaultCashflowRecurringOccurrences;
  CashflowViewAs cashflowViewAs = CashflowViewAs.sankey;

  ///---------------------------------
  /// Observable enum
  ViewId currentView = ViewId.viewCashFlow;

  List<String> mru = <String>[];
  int netWorthEventThreshold = _defaultNetWorthEventThreshold;
  bool trendIncludeAssetAccounts = false;

  String _apiKeyForStocks = '';
  String _localeCode = SharedStrings.localeCodeEnglish;
  bool _includeClosedAccounts = false;

  ///---------------------------------
  /// Include Rental feature
  bool _includeRentalManagement = false;

  ///---------------------------------
  /// SidePanel
  ///
  /// Expand/Collapse
  bool _isSidePanelExpanded = false;

  /// GET
  bool get isSidePanelExpanded => _isSidePanelExpanded;

  /// SET
  set isSidePanelExpanded(bool value) {
    _isSidePanelExpanded = value;

    // persist
    setBool(settingKeySidePanelExpanded, value);
    notifyListeners();
  }

  ///---------------------------------
  /// SidePanel Height
  ///
  /// Expand/Collapse
  int _sidePanelHeight = Constants.sidePanelHeightWhenExpanded;

  /// GET
  int get sidePanelHeight => _sidePanelHeight;

  /// SET
  set sidePanelHeight(int value) {
    _sidePanelHeight = value;

    // persist; no notify: only the splitter that sets it reads it, and it is set on every drag frame
    setInt(settingKeySidePanelHeight, value);
  }

  ///---------------------------------
  /// Selected SidePanel Tab
  SidePanelSubViewEnum _selectedSidePanelTabId = SidePanelSubViewEnum.details;

  /// GET
  SidePanelSubViewEnum get selectedSidePanelTabId => _selectedSidePanelTabId;

  /// SET
  set selectedSidePanelTabId(SidePanelSubViewEnum value) {
    _selectedSidePanelTabId = value;
    // persist
    setInt(settingKeySelectedSidePanelTab, value.index);
    notifyListeners();
  }

  //////////////////////////////////////////////////////
  // Persistable user preference

  ///---------------------------------
  /// Text Font Size/Scale
  double _textScale = 1.0;

  /// Global access to the live app preference controller.
  static PreferenceController? instance;

  SharedPreferences? _preferences;

  /// Starts preference loading and initial route selection.
  Future<void> start() async {
    await init();
    if (mru.isNotEmpty) {
      DataAccess.loadLastFileSaved();
    } else {
      // queue changing screen after app loaded
      Future<Null>.delayed(const Duration(milliseconds: DurationInMs.quick), () {
        AppRouter.pushReplacementNamed<dynamic, dynamic>(Constants.routeWelcomePage);
      });
    }
  }

  /// Adds an item to the MRU (most recently used) list.
  void addToMRU(String filePathAndName) {
    if (filePathAndName.isNotEmpty) {
      // load and place on top
      mru.remove(filePathAndName);
      mru.insert(0, filePathAndName);

      // save it
      if (_preferences != null) {
        _preferences!.setStringList(settingKeyMRU, mru);
      }
      notifyListeners();
    }
  }

  ///---------------------------------
  /// Stock quote API Key
  String get apiKeyForStocks => _apiKeyForStocks;

  /// Returns the persisted app locale code, one of [AppLocalizations.supportedLocales].
  String get localeCode => _localeCode;

  /// Sets app locale, persists it; unsupported codes fall back to English.
  set localeCode(String value) {
    final bool isSupported = AppLocalizations.supportedLocales.any((Locale locale) => locale.languageCode == value);
    final String sanitized = isSupported ? value : SharedStrings.localeCodeEnglish;
    _localeCode = sanitized;
    setString(settingKeyLocale, sanitized);
    notifyListeners();
  }

  ///---------------------------------
  set apiKeyForStocks(String value) {
    _apiKeyForStocks = value;
    setString(settingKeyStockApiKey, value);
    notifyListeners();
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

  /// Returns the enum value stored by index under [key], or [fallback] when none is
  /// stored or the stored index is no longer valid (for example after a value was removed).
  T _getEnum<T extends Enum>(String key, List<T> values, T fallback) {
    final int index = getInt(key, fallback.index);
    return index >= 0 && index < values.length ? values[index] : fallback;
  }

  // Retrieve a string value from preferences
  /// Returns a string value from preferences with optional default.
  String getString(String key, [String defaultValueIfNotFound = '']) =>
      _preferences?.getString(key) ?? defaultValueIfNotFound;

  // Retrieve a list of strings from preferences
  /// Returns a string list from preferences with optional default.
  Future<List<String>> getStringList(String key) async => _preferences?.getStringList(key) ?? <String>[];

  /// Returns a unique state string combining key preference values.
  String get getUniqueState =>
      '${SharedStrings.preferenceStateReady}$isReady '
      '${SharedStrings.preferenceStateRental}$includeRentalManagement '
      '${SharedStrings.preferenceStateIncludeClosedAccounts}$includeClosedAccounts '
      '${SharedStrings.preferenceStateTextScale}$textScale';

  ///---------------------------------
  /// Show or Hide Account that are marked as Closed
  /// Hide/Show Closed Accounts
  /// Returns whether closed accounts should be included in views.
  bool get includeClosedAccounts => _includeClosedAccounts;

  /// Sets whether closed accounts should be included in views.
  set includeClosedAccounts(bool value) {
    _includeClosedAccounts = value;
    setBool(settingKeyIncludeClosedAccounts, value);
    notifyListeners();
  }

  ///--------------------------------
  /// Rental
  /// Returns whether rental management should be included in views.
  bool get includeRentalManagement => _includeRentalManagement;

  /// Sets whether rental management should be included in views.
  set includeRentalManagement(bool value) {
    _includeRentalManagement = value;
    setBool(settingKeyRentalsSupport, value);
    notifyListeners();
  }

  /// Initializes preferences and loads stored values.
  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
    await loadDefaults();
    isReady = true;
    notifyListeners();
  }

  /// Navigates to [viewId] with [selectedId] selected, replacing its text and column filters with
  /// [textFilter] and [columnFilters] (none when null), so a stale filter can't hide the item jumped to.
  Future<void> jumpToView({
    required ViewId viewId,
    required int selectedId,
    String textFilter = '',
    FieldFilters? columnFilters,
  }) async {
    // First set all filters on the destination view
    await setString(
      viewId.getViewPreferenceId(settingKeyFilterText),
      textFilter,
    );
    await setString(
      viewId.getViewPreferenceId(settingKeyFiltersColumns),
      columnFilters?.toJsonString() ?? '',
    );

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
    mru = _preferences!.getStringList(settingKeyMRU) ?? <String>[];

    // Side Panel Expanded/Collapsed
    _isSidePanelExpanded = getBool(settingKeySidePanelExpanded, false);

    // Side Panel Height
    _sidePanelHeight = getInt(
      settingKeySidePanelHeight,
      isSidePanelExpanded ? Constants.sidePanelHeightWhenExpanded : Constants.sidePanelHeightWhenCollapsed,
    );

    _includeClosedAccounts = getBool(
      settingKeyIncludeClosedAccounts,
      false,
    );
    _includeRentalManagement = getBool(settingKeyRentalsSupport, false);
    _apiKeyForStocks = getString(settingKeyStockApiKey, '');
    _localeCode = getString(settingKeyLocale, SharedStrings.localeCodeEnglish);
    _textScale = getDouble(settingKeyTextScale, _textScale);
    notifyListeners();

    cashflowViewAs = _getEnum(settingKeyCashflowView, CashflowViewAs.values, CashflowViewAs.sankey);
    budgetViewAsForIncomes = _getEnum(settingKeyBudgetViewAsIncomes, BudgetViewAs.values, BudgetViewAs.list);
    budgetViewAsForExpenses = _getEnum(settingKeyBudgetViewAsExpenses, BudgetViewAs.values, BudgetViewAs.list);
    cashflowRecurringOccurrences = getInt(
      settingKeyCashflowRecurringOccurrences,
      _defaultCashflowRecurringOccurrences,
    );
    netWorthEventThreshold = getInt(_settingKeyNetWorthEventThreshold, _defaultNetWorthEventThreshold);
    trendIncludeAssetAccounts = getBool(_settingKeyTrendIncludeAssetAccounts, false);
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
    currentView = view;
    notifyListeners();
  }

  /// Sets the cashflow visualization mode.
  void setCashflowViewAs(CashflowViewAs viewAs) {
    cashflowViewAs = viewAs;
    setInt(settingKeyCashflowView, viewAs.index);
    notifyListeners();
  }

  /// Sets the budget presentation for income cards.
  void setBudgetViewAsForIncomes(BudgetViewAs viewAs) {
    budgetViewAsForIncomes = viewAs;
    setInt(settingKeyBudgetViewAsIncomes, viewAs.index);
    notifyListeners();
  }

  /// Sets the budget presentation for expense cards.
  void setBudgetViewAsForExpenses(BudgetViewAs viewAs) {
    budgetViewAsForExpenses = viewAs;
    setInt(settingKeyBudgetViewAsExpenses, viewAs.index);
    notifyListeners();
  }

  /// Sets the net worth chart anomaly threshold and persists it.
  void setNetWorthEventThreshold(int value) {
    netWorthEventThreshold = value;
    setInt(_settingKeyNetWorthEventThreshold, value);
    notifyListeners();
  }

  /// Sets whether asset accounts are included in trend mode.
  void setTrendIncludeAssetAccounts(bool value) {
    trendIncludeAssetAccounts = value;
    setBool(_settingKeyTrendIncludeAssetAccounts, value);
    notifyListeners();
  }

  /// Returns the current text scale factor.
  double get textScale => _textScale;

  /// Sets the text scale factor and saves to preferences.
  set textScale(double value) {
    _textScale = value;
    setDouble(settingKeyTextScale, textScale);
    notifyListeners();
  }

  /// Returns the singleton PreferenceController instance.
  static PreferenceController get to => instance ??= PreferenceController();
}
