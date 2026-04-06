import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/presentation/services/app_scope_service.dart';
import 'package:money/widgets/components/text_title_widget.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/state/theme_controller.dart';

const double _settingsSectionSpacing = 12.0;
const double _settingsCardRadius = 8.0;

const List<_LocaleOption> _localeOptions = <_LocaleOption>[
  _LocaleOption(code: 'en', labelKey: AppTranslationKeys.languageEnglish),
  _LocaleOption(code: 'es', labelKey: AppTranslationKeys.languageSpanish),
  _LocaleOption(code: 'fr', labelKey: AppTranslationKeys.languageFrench),
];

/// Represents a supported locale option in settings.
class _LocaleOption {
  /// Creates a locale option with locale [code] and translation [labelKey].
  const _LocaleOption({
    required this.code,
    required this.labelKey,
  });

  /// Locale code persisted in preferences.
  final String code;

  /// Translation key used for the locale display name.
  final String labelKey;
}

/// Displays the settings route content.
class SettingsPage extends StatelessWidget {
  /// Creates a settings page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppServices services = AppScope.of(context);
    final PreferenceController preferenceController = services.preferenceController;
    final ThemeController themeController = services.themeController;
    final Listenable controllers = Listenable.merge(<Listenable>[
      preferenceController,
      themeController,
    ]);

    return AnimatedBuilder(
      animation: controllers,
      builder: (BuildContext context, Widget? _) {
        return Scaffold(
          appBar: AppBar(
            title: TextTitle(AppL10n.tr(AppTranslationKeys.settings)),
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          ),
          body: ListView(
            padding: const EdgeInsets.all(SizeForPadding.xlarge),
            children: <Widget>[
              _buildClosedAccountsCard(preferenceController),
              const SizedBox(height: _settingsSectionSpacing),
              _buildLanguageCard(preferenceController),
              const SizedBox(height: _settingsSectionSpacing),
              _buildThemeModeCard(themeController),
            ],
          ),
        );
      },
    );
  }

  /// Builds the closed-account visibility settings card.
  Widget _buildClosedAccountsCard(
    PreferenceController preferenceController,
  ) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_settingsCardRadius),
      ),
      child: SwitchListTile.adaptive(
        secondary: const Icon(Icons.inventory_2_outlined),
        title: Text(AppL10n.tr(AppTranslationKeys.viewClosedAccounts)),
        subtitle: Text(
          preferenceController.includeClosedAccounts
              ? AppL10n.tr(AppTranslationKeys.hideClosedAccounts)
              : AppL10n.tr(AppTranslationKeys.showClosedAccounts),
        ),
        value: preferenceController.includeClosedAccounts,
        onChanged: (bool value) => preferenceController.includeClosedAccounts = value,
      ),
    );
  }

  /// Builds the language selection settings card.
  Widget _buildLanguageCard(
    PreferenceController preferenceController,
  ) {
    final String selectedLocaleCode = _selectedLocaleCode(preferenceController.localeCode);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_settingsCardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SizeForPadding.normal),
        child: Row(
          children: <Widget>[
            const Icon(Icons.language),
            const SizedBox(width: SizeForPadding.normal),
            Expanded(
              child: Text(AppL10n.tr(AppTranslationKeys.language)),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedLocaleCode,
                items: _localeOptions
                    .map(
                      (_LocaleOption option) => DropdownMenuItem<String>(
                        value: option.code,
                        child: Text(AppL10n.tr(option.labelKey)),
                      ),
                    )
                    .toList(),
                onChanged: (String? value) {
                  if (value == null) {
                    return;
                  }
                  preferenceController.localeCode = value;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the theme mode settings card.
  Widget _buildThemeModeCard(ThemeController themeController) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_settingsCardRadius),
      ),
      child: SwitchListTile.adaptive(
        secondary: Icon(
          themeController.isDarkTheme ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
        ),
        title: Text(AppL10n.tr(AppTranslationKeys.toggleBrightness)),
        value: themeController.isDarkTheme,
        onChanged: (bool _) => themeController.toggleThemeMode(),
      ),
    );
  }

  /// Returns a locale code that exists in [_localeOptions].
  String _selectedLocaleCode(String localeCode) {
    for (final _LocaleOption option in _localeOptions) {
      if (option.code == localeCode) {
        return option.code;
      }
    }
    return _localeOptions.first.code;
  }
}
