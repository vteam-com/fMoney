import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/providers/currency.dart';
import 'package:money/views/data.dart';
import 'package:money/widgets/app_scaffold.dart';
import 'package:money/widgets/preferences_controller.dart';
import 'package:money/widgets/pure/box.dart';
import 'package:money/widgets/pure/my_text_input.dart';
import 'package:money/widgets/text_title.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const double _settingsSectionDividerHeight = 50.0;

/// The `SettingsPage` class represents the settings page of the application.
/// This page allows the user to manage various settings, such as rental management, stock service API key, and currencies.
class SettingsPage extends StatelessWidget {
  /// Constructs a `SettingsPage` widget with the provided [key].
  const SettingsPage({super.key});

  /// Builds the settings page UI.
  @override
  Widget build(BuildContext context) {
    final String localeCode = Localizations.localeOf(context).languageCode;
    return myScaffold(
      context,
      AppBar(title: TextTitle(AppL10n.tr(AppTranslationKeys.settings)), centerTitle: true),
      Center(
        child: SingleChildScrollView(
          child: Box(
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  title: Text(AppL10n.tr(AppTranslationKeys.rental)),
                  subtitle: Text(
                    AppL10n.tr(AppTranslationKeys.manageTheExpensesAndRentalIncomeOfProperties),
                  ),
                  value: PreferenceController.to.includeRentalManagement,
                  onChanged: (bool _) {
                    PreferenceController.to.includeRentalManagement = !PreferenceController.to.includeRentalManagement;
                  },
                ),
                _buildLanguageControl(localeCode),
                const Divider(height: _settingsSectionDividerHeight),
                MyTextInput(
                  hintText: 'Stock service API key from https://twelvedata.com',
                  controller: TextEditingController()..text = PreferenceController.to.apiKeyForStocks,
                ),
                const Divider(height: _settingsSectionDividerHeight),
                _buildCurrenciesPanel(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the currencies panel showing configured currencies and their display formats.
  Widget _buildCurrenciesPanel(final BuildContext context) {
    final List<Widget> widgets = <Widget>[];

    for (final Currency currency in Data().currencies.iterableList()) {
      widgets.add(
        Container(
          decoration: BoxDecoration(
            color: getColorTheme(context).surfaceContainerHighest,
            border: Border.all(color: getColorTheme(context).outline),
            borderRadius: const BorderRadius.all(Radius.circular(SizeForRadius.small)),
          ),
          margin: const EdgeInsets.all(SizeForPadding.xsmall),
          padding: const EdgeInsets.all(SizeForPadding.xsmall),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(currency.fieldName.value),
                  buildCurrencyWidget(currency.fieldSymbol.value),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(currency.fieldRatio.value.toString()),
                  Text(currency.fieldCultureCode.value),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  /// Builds the language selector that switches the active app locale.
  Widget _buildLanguageControl(final String localeCode) {
    return ListTile(
      title: Text(AppL10n.tr(AppTranslationKeys.language)),
      subtitle: SegmentedButton<String>(
        segments: <ButtonSegment<String>>[
          ButtonSegment<String>(
            value: 'en',
            label: Text(AppL10n.tr(AppTranslationKeys.languageEnglish)),
          ),
          ButtonSegment<String>(
            value: 'fr',
            label: Text(AppL10n.tr(AppTranslationKeys.languageFrench)),
          ),
        ],
        selected: <String>{localeCode == 'fr' ? 'fr' : 'en'},
        onSelectionChanged: (Set<String> selection) {
          final String newLocaleCode = selection.first;
          PreferenceController.to.localeCode = newLocaleCode;
        },
      ),
    );
  }
}
