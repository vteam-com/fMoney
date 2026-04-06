import 'package:flutter/foundation.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/shared/presentation/widgets/zoom_widget.dart';
import 'package:money/views/imports/import_wizard_view.dart';
import 'package:money/views/imports/shared/transactions_text_import_view.dart';
import 'package:money/views/shell/app_title_widget.dart';
import 'package:money/widgets/components/popup_menu_icon_button.dart';
import 'package:money/widgets/components/three_part_label_widget.dart';
import 'package:money/widgets/pure/color_palette_widget.dart';
import 'package:money/widgets/pure/scale_down_widget.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/state/theme_controller.dart';

const double _opacityEnabled = 1.0;
const double _opacityDisabled = 0.5;
const double _colorPaletteHeight = 300.0;
const double _appBarHeight = 64.0;
const double _inventoryIconSize = 18.0;
const int _debugMenuValue = -1;

/// A stateless widget for my app bar.
class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MyAppBar({super.key});

  /// The size this widget would prefer if it were otherwise unconstrained.
  @override
  final Size preferredSize = const Size.fromHeight(_appBarHeight);

  /// Builds the application app bar.
  @override
  Widget build(BuildContext context) {
    final AppServices services = AppScope.of(context);
    final ThemeController themeController = services.themeController;
    final PreferenceController preferencesController = services.preferenceController;

    return AppBar(
      toolbarHeight: _appBarHeight,
      backgroundColor: getColorTheme(context).secondaryContainer,
      leading: _buildPopupMenu(context),
      title: AppTitle(),
      actions: <Widget>[
        if (!context.isWidthSmall) _buildToggleClosedAccountsButton(preferencesController),
        _buildToggleThemeButton(themeController),
        _buildSettingsMenu(context, themeController, preferencesController),
      ],
    );
  }

  /// Handles app bar actions such as add transactions, settings, and theme changes.
  void onAppBarAction(BuildContext context, int value) {
    switch (value) {
      case Constants.commandAddTransactions:
        showImportTransactionsFromTextInput(context);
        DataFileController.to.update();
        break;
      case Constants.commandSettings:
        Navigator.of(context).pushNamed(Constants.routeSettingsPage);
        break;
      case Constants.commandInstallPlatforms:
        Navigator.of(context).pushNamed(Constants.routeInstallPlatformsPage);
        break;
      case Constants.commandAbout:
        Navigator.of(context).pushNamed(Constants.routeAboutPage);
        break;
      case Constants.commandIncludeClosedAccount:
        PreferenceController.to.includeClosedAccounts = !PreferenceController.to.includeClosedAccounts;
        DataFileController.to.update();
        break;
      default:
        ThemeController.to.setThemeColor(value);
        DataFileController.to.update();
    }
  }

  /// Builds a popup menu item for the app bar menu.
  PopupMenuItem<int> _buildMenuItem(
    int value,
    String caption,
    IconData iconData, {
    String? shortcut,
  }) {
    return PopupMenuItem<int>(
      value: value,
      child: ThreePartLabel(
        icon: Icon(iconData),
        text1: caption,
        text2: shortcut ?? '',
        small: true,
      ),
    );
  }

  /// Builds the main file/actions popup menu for the app bar.
  Widget _buildPopupMenu(BuildContext context) {
    final List<PopupMenuItem<int>> menuItems = <PopupMenuItem<int>>[
      _buildMenuItem(
        Constants.commandFileNew,
        AppL10n.tr(AppTranslationKeys.newMenuItem),
        Icons.note_add_outlined,
        shortcut: AppL10n.tr(AppTranslationKeys.shortcutNewFile),
      ),
      _buildMenuItem(
        Constants.commandFileOpen,
        AppL10n.tr(AppTranslationKeys.openMenuItem),
        Icons.file_open_outlined,
        shortcut: AppL10n.tr(AppTranslationKeys.shortcutOpenFile),
      ),
      _buildMenuItem(
        Constants.commandAddTransactions,
        AppL10n.tr(AppTranslationKeys.addTransactionsMenuItem),
        Icons.post_add_outlined,
        shortcut: AppL10n.tr(AppTranslationKeys.shortcutAddTransactions),
      ),
      _buildMenuItem(
        Constants.commandRebalance,
        AppL10n.tr(AppTranslationKeys.rebalanceMenuItem),
        Icons.refresh_outlined,
        shortcut: AppL10n.tr(AppTranslationKeys.shortcutRebalance),
      ),
      if (!kIsWeb && !isPlatformMobile())
        _buildMenuItem(
          Constants.commandFileLocation,
          AppL10n.tr(AppTranslationKeys.fileLocationMenuItem),
          Icons.folder_open_outlined,
        ),
      if (!kIsWeb) ...<PopupMenuItem<int>>[
        _buildMenuItem(Constants.commandFileSaveCsv, AppL10n.tr(AppTranslationKeys.saveToCsv), Icons.save),
        _buildMenuItem(Constants.commandFileSaveSql, AppL10n.tr(AppTranslationKeys.saveToSql), Icons.save),
      ],
      _buildMenuItem(Constants.commandFileClose, AppL10n.tr(AppTranslationKeys.closeFile), Icons.close),
    ];

    return myPopupMenuIconButton(
      key: const Key('key_menu_button'),
      context: context,
      icon: Icons.menu,
      tooltip: AppL10n.tr(AppTranslationKeys.fileMenuTooltip),
      list: menuItems,
      onSelected: _handleMenuSelection,
    );
  }

  /// Builds the settings popup menu, including theme and platform actions.
  Widget _buildSettingsMenu(
    BuildContext context,
    ThemeController themeController,
    PreferenceController preferencesController,
  ) {
    final List<PopupMenuItem<int>> actionList = <PopupMenuItem<int>>[
      _buildSettingsMenuItem(
        Constants.commandIncludeClosedAccount,
        preferencesController.includeClosedAccounts
            ? AppL10n.tr(AppTranslationKeys.hideClosedAccounts)
            : AppL10n.tr(AppTranslationKeys.showClosedAccounts),
        Icons.inventory,
        opacity: preferencesController.includeClosedAccounts ? _opacityEnabled : _opacityDisabled,
      ),
      _buildSettingsMenuItem(
        Constants.commandSettings,
        AppL10n.tr(AppTranslationKeys.settingsMenuItem),
        Icons.settings,
        key: const Key('key_settings'),
      ),
      _buildSettingsMenuItem(
        Constants.commandInstallPlatforms,
        AppL10n.tr(AppTranslationKeys.installAppMenuItem),
        Icons.install_desktop,
        key: Constants.keyPlatformsButton,
      ),
      _buildSettingsMenuItem(
        Constants.commandAbout,
        AppL10n.tr(AppTranslationKeys.aboutMenuItem),
        Icons.info_outline,
        key: const Key('key_about'),
      ),
      ...themeController.buildThemeColorMenuItems(context),
      PopupMenuItem<int>(
        value: Constants.commandTextZoom,
        child: ZoomIncreaseDecrease(
          title: AppL10n.tr(AppTranslationKeys.zoom),
          onDecrease: ThemeController.to.fontScaleDecrease,
          onIncrease: ThemeController.to.fontScaleIncrease,
        ),
      ),
    ];

    if (kDebugMode) {
      actionList.add(
        const PopupMenuItem<int>(
          value: _debugMenuValue,
          child: SizedBox(
            height: _colorPaletteHeight,
            child: SingleChildScrollView(child: ColorPalette()),
          ),
        ),
      );
    }

    return myPopupMenuIconButton(
      key: Constants.keySettingsButton,
      context: context,
      icon: Icons.settings_outlined,
      tooltip: AppL10n.tr(AppTranslationKeys.settings),
      list: actionList,
      onSelected: (int value) => onAppBarAction(context, value),
    );
  }

  /// Builds a single settings menu item with optional opacity and key.
  PopupMenuItem<int> _buildSettingsMenuItem(
    int value,
    String text,
    IconData iconData, {
    Key? key,
    double opacity = _opacityEnabled,
  }) {
    return PopupMenuItem<int>(
      value: value,
      child: ThreePartLabel(
        key: key,
        text1: text,
        icon: Opacity(
          opacity: opacity,
          child: Icon(iconData, color: Colors.grey),
        ),
        small: true,
      ),
    );
  }

  /// Builds an icon button that toggles inclusion of closed accounts.
  Widget _buildToggleClosedAccountsButton(
    PreferenceController preferencesController,
  ) {
    return IconButton(
      icon: Opacity(
        opacity: preferencesController.includeClosedAccounts ? _opacityEnabled : _opacityDisabled,
        child: const Icon(Icons.inventory, size: _inventoryIconSize),
      ),
      onPressed: () => preferencesController.includeClosedAccounts = !preferencesController.includeClosedAccounts,
      tooltip: preferencesController.includeClosedAccounts
          ? AppL10n.tr(AppTranslationKeys.hideClosedAccounts)
          : AppL10n.tr(AppTranslationKeys.viewClosedAccounts),
    );
  }

  /// Builds an icon button that toggles light/dark theme mode.
  Widget _buildToggleThemeButton(ThemeController themeController) {
    return IconButton(
      key: const Key('key_toggle_mode'),
      icon: Icon(
        themeController.isDarkTheme ? Icons.wb_sunny : Icons.mode_night,
      ),
      onPressed: ThemeController.to.toggleThemeMode,
      tooltip: AppL10n.tr(AppTranslationKeys.toggleBrightness),
    );
  }

  /// Handles selections from the main file/actions popup menu.
  void _handleMenuSelection(int index) {
    switch (index) {
      case Constants.commandFileNew:
        AppRouter.pushNamedAndRemoveUntil<dynamic>(Constants.routeHomePage);
        DataFileController.to.onFileNew();
        break;
      case Constants.commandFileOpen:
        DataFileController.to.onFileOpen().then((_) {
          AppRouter.pushNamedAndRemoveUntil<dynamic>(Constants.routeHomePage);
        });
        break;
      case Constants.commandFileLocation:
        DataFileController.to.onShowFileLocation();
        break;
      case Constants.commandAddTransactions:
        showImportTransactionsWizard();
        break;
      case Constants.commandRebalance:
        Data().recalculateBalances();
        break;
      case Constants.commandFileSaveCsv:
        DataFileController.to.onSaveToCsv();
        break;
      case Constants.commandFileSaveSql:
        DataFileController.to.onSaveToSql();
        break;
      case Constants.commandFileClose:
        DataFileController.to.closeFile();
        AppRouter.pushNamedAndRemoveUntil<dynamic>(Constants.routeWelcomePage);
        break;
      default:
        debugPrint('Unhandled menu item: $index');
    }
  }
}
