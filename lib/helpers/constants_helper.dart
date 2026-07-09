// ignore: fcheck_one_class_per_file
import 'package:flutter/material.dart';

const String settingKeyCashflowRecurringOccurrences = 'keyCashflowOccurrences';
const String settingKeyCashflowView = 'keyCashflowView';
const String settingKeyBudgetViewAsIncomes = 'keyBudgetViewAsIncomes';
const String settingKeyBudgetViewAsExpenses = 'keyBudgetViewAsExpenses';
const String settingKeyDarkMode = 'themeDarkMode';
const String settingKeyTheme = 'themeColor';
const String settingKeySidePanelExpanded = 'isSidePanelExpanded';
const String settingKeySidePanelHeight = 'sidePanelHeight';
const String settingKeyDomainAccountsInfoTransactions = 'accountDetailsTransactions';
const String settingKeyFilterText = 'filterText';
const String settingKeyFiltersColumns = 'filtersColumns';
const String settingKeyIncludeClosedAccounts = 'includeClosedAccounts';
const String settingKeyMRU = 'mru';
const String settingKeyLocale = 'locale';
const String settingKeyRentalsSupport = 'rentals';
const String settingKeySelectedSidePanelTab = 'selectedSidePanelTab';
const String settingKeySelectedListItemId = 'selectedItemId';
const String settingKeySortAscending = 'sortAscending';
const String settingKeySortBy = 'sortBy';
const String settingKeyStockApiKey = 'stockServiceApiKey';
const String settingKeyTextScale = 'textScale';

/// Preference key suffix for persisted AI prompt draft text.
const String settingKeyAiPromptDraftText = 'aiPromptDraftText';
const String settingKeySidePanel = 'side_panel_';
const String settingKeyDomainAccounts = 'accounts';
const String settingKeyDomainCategories = 'categories';
const String settingKeyDomainPayees = 'payees';

/// Use when a callback/method signature requires a parameter that is currently unused.
void keepUnused([Object? value1, Object? value2, Object? value3, Object? value4]) {
  if (value1 == null && value2 == null && value3 == null && value4 == null) {
    return;
  }
}

/// Represents constants.
class Constants {
  static const int commandAddTransactions = 1400;
  static const int commandFileClose = 2006;
  static const int commandFileLocation = 2002;
  static const int commandFileNew = 2000;
  static const int commandFileOpen = 2001;
  static const int commandFileSaveCsv = 2004;
  static const int commandFileSaveSql = 2005;
  static const int commandRebalance = 1500;
  static const int commandSettings = 1100;
  static const int commandIncludeClosedAccount = 1200;
  static const int commandInstallPlatforms = 1300;
  static const int commandTextZoom = 1000;
  static const int commandAbout = 1600;
  static const int flex2x = 2;

  static const int sidePanelHeightCollapsedDefault = 52;
  static const int sidePanelHeightExpandedDefault = 380;
  static int sidePanelHeightWhenCollapsed = sidePanelHeightCollapsedDefault;
  static int sidePanelHeightWhenExpanded = sidePanelHeightExpandedDefault;

  static const String defaultCurrency = 'USD';
  static String fakeStockApiKey = 'fakeStockApiKey';
  static const double gapBetweenChannels = 14.0;
  static const Key keyAccountPicker = Key('key_account_picker');
  // Keys
  static const Key keyAddNewItem = Key('key_add_new_item');

  static const Key keyButtonAddTransactions = Key(
    'key_button_add_transactions',
  );
  static const Key keyButtonApplyOrDone = Key('key_button_apply_done');
  static const Key keyButtonCancel = Key('key_button_cancel');
  static const Key keyButtonEdit = Key('key_button_edit');
  static const Key keyCheckboxToggleSelectAll = Key(
    'key_checkbox_toggle_select_all',
  );
  static const Key keyCopyListToClipboardHeaderMain = Key(
    'keyCopyListToClipboardHeaderMain',
  );
  static const Key keyCopyListToClipboardHeaderSidePanel = Key(
    'keyCopyListToClipboardHeaderSidePanel',
  );
  static const Key keyDatePicker = Key('key_date_picker');
  static const Key keyDeleteSelectedItems = Key('key_delete_button');
  static const Key keyEditSelectedItems = Key('key_edit_item');
  static const Key keyItemEdit = Key('key_item_edit');
  static const Key keyMergeButton = Key('key_merge_button');
  static const Key keyMruButton = Key('key_mru_button');
  static const Key keyMultiSelectionToggle = Key('key_multi_selection_toggle');
  static const Key keyPendingChanges = Key('key_pending_changes');
  static const Key keySettingsButton = Key('key_settings_button');
  static const Key keyPlatformsButton = Key('key_platforms_button');
  static const Key keySidePanelExpando = Key('key_side_panel_expando');
  static const Key keyZoomDecrease = Key('keyZoomDecrease');
  static const Key keyZoomIncrease = Key('keyZoomIncrease');
  static const Key keyZoomNormal = Key('keyZoomNormal');
  static const double minBlockHeight = 3.0;
  static String mockStockSymbol = '<not real>';
  static String routeHomePage = '/home';
  static String routePolicyPage = '/policy';
  static String routeSettingsPage = '/settings';
  static String routeInstallPlatformsPage = '/platforms';
  static String routeAboutPage = '/about';
  static String routeWelcomePage = '/welcome';
  static const double sanKeyColumnWidth = 200.0;
  static const double screenWidthLarge = 1800;
  static const double screenWidthMedium = 1200;
  static const double screenWidthSmall = 600;

  static const double targetHeight = 200.0;
  static const double platformButtonSpacing = 16.0;
  static const double loadingPadding = 16.0;
  static const double aboutPagePadding = 16.0;
  static const double aboutSectionSpacing = 24.0;
  static const double aboutIconSize = 8.0;
  static const double aboutInfoRowSpacing = 4.0;
  static const double aboutInfoLabelWidth = 120.0;
  static const double aboutVersionSpacing = 12.0;
  static const double aboutLicenseIconSize = 48.0;
  static const int httpStatusOk = 200;
  static String untitledFileName = 'Untitled';
  static String viewStockFieldNameAccount = 'Account';
  static String viewStockFieldNameSymbol = 'Symbol';
  static String viewTransactionFieldNameAccount = 'Account';
  static String viewTransactionFieldNameCategory = 'Category';
  static String viewTransactionFieldNameDate = 'Date';
  static String viewTransactionFieldNamePayee = 'Payee/Transfer';
}

/// Represents size for padding.
class SizeForPadding {
  static const double nano = 2;
  static const double small = 3;
  static const double medium = 5;
  static const double normal = 8;
  static const double large = 13;
  static const double huge = 21;
}

/// Represents common corner radii.
class SizeForRadius {
  static const double small = 4;
  static const double normal = 8;
}

/// Represents common animation and delay durations in milliseconds.
class DurationInMs {
  static const int quick = 100;
  static const int normal = 300;
  static const int slow = 500;
}

/// Represents default window dimensions.
class SizeForWindow {
  static const double desktopWidth = 800;
  static const double desktopHeight = 600;
}

/// Represents size for text.
class SizeForText {
  static const double small = 8;
  static const double medium = 13;
  static const double large = 21;
  static const double huge = 34;
}

/// Represents size for icon.
class SizeForIcon {
  static const double small = 13;
  static const double medium = 21;
  static const double large = 34;
  static const double huge = 55;
}

/// Represents int values.
class IntValues {
  static const int minBitCount = 1;
  static const int maxBitCount = 64;

  /// Returns maximum signed integer value for specified bit count.
  static int maxSigned(int bitCount) {
    RangeError.checkValueInInterval(bitCount, minBitCount, maxBitCount);
    return (1 << (bitCount - 1)) - 1;
  }

  /// Returns minimum signed integer value for specified bit count.
  static int minSigned(int bitCount) {
    RangeError.checkValueInInterval(bitCount, minBitCount, maxBitCount);
    return -1 << (bitCount - 1);
  }
}

enum ViewId {
  viewCashFlow,
  viewEvents,
  viewAccounts,
  viewCategories,
  viewPayees,
  viewAliases,
  viewTransactions,
  viewTransfers,
  viewInvestments,
  viewStocks,
  viewRentals,
  viewAI,
  viewPolicy,
}

enum SidePanelSubViewEnum { details, chart, transactions, pnl }

enum CashflowViewAs { sankey, netWorthOverTime, budget, trend }

enum BudgetViewAs { list, chart, recurrences, suggestions }

extension ViewExtension on ViewId {
  /// Returns preference ID for the view with specified suffix.
  String getViewPreferenceId(final String suffix) {
    // ignore: unnecessary_this
    return '${this.name.toLowerCase()}_$suffix';
  }

  /// Returns the IconData for the view.
  IconData getIconData() {
    switch (this) {
      case ViewId.viewCashFlow:
        return Icons.query_stats_outlined;
      case ViewId.viewAccounts:
        return Icons.account_balance_outlined;
      case ViewId.viewCategories:
        return Icons.category_outlined;
      case ViewId.viewPayees:
        return Icons.groups_3_outlined;
      case ViewId.viewAliases:
        return Icons.how_to_reg_outlined;
      case ViewId.viewTransactions:
        return Icons.receipt_long_outlined;
      case ViewId.viewTransfers:
        return Icons.swap_horiz_outlined;
      case ViewId.viewInvestments:
        return Icons.stacked_line_chart_outlined;
      case ViewId.viewStocks:
        return Icons.candlestick_chart_outlined;
      case ViewId.viewRentals:
        return Icons.location_city_outlined;
      case ViewId.viewEvents:
        return Icons.event_outlined;
      case ViewId.viewPolicy:
        return Icons.policy_outlined;
      case ViewId.viewAI:
        return Icons.smart_toy_outlined;
    }
  }

  /// Returns an Icon widget for the view.
  Icon getIcon() {
    return Icon(getIconData());
  }
}

/// Represents my keys.
class MyKeys {
  static const Key keyHeaderFilterTextInput = Key('key_header_filter_input');
}
