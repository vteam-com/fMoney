import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/generated_app_version_data.dart';

/// A page displaying app version information and licenses.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String _appIconAssetPath = 'assets/main_icon.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppL10n.tr(AppTranslationKeys.about)),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Constants.aboutPagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildAppInfo(context),
            const SizedBox(height: Constants.aboutSectionSpacing),
            _buildVersionInfo(context),
            const SizedBox(height: Constants.aboutSectionSpacing),
            _buildLicenseSection(context),
          ],
        ),
      ),
    );
  }

  /// Builds the app information section displaying the app name,
  /// description, and long description in a styled card.
  Widget _buildAppInfo(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return _buildSectionCard(
      children: <Widget>[
        Text(
          AppL10n.tr(AppTranslationKeys.appName),
          style: textTheme.headlineMedium,
        ),
        const SizedBox(height: Constants.aboutTextSpacing),
        Text(
          AppL10n.tr(AppTranslationKeys.appDescription),
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: Constants.aboutTextSpacing),
        Text(
          AppL10n.tr(AppTranslationKeys.appLongDescription),
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }

  /// Builds a row displaying a label-value pair with consistent styling.
  /// Used in the version information section to show version details.
  ///
  /// [bodyStyle] is the base text style applied to both label and value.
  /// [label] is the descriptor text (e.g., "Version", "Build Number").
  /// [value] is the corresponding value to display.
  Widget _buildInfoRow(TextStyle? bodyStyle, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Constants.aboutInfoRowSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: Constants.aboutInfoLabelWidth,
            child: Text(
              label,
              style: bodyStyle?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: bodyStyle,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the licenses section with license information
  /// and a button to view detailed licenses for all dependencies.
  Widget _buildLicenseSection(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return _buildSectionCard(
      children: <Widget>[
        Text(
          AppL10n.tr(AppTranslationKeys.licenses),
          style: textTheme.titleLarge,
        ),
        const SizedBox(height: Constants.aboutVersionSpacing),
        Text(
          AppL10n.tr(AppTranslationKeys.licensesDescription),
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: Constants.aboutSectionSpacing),
        ElevatedButton.icon(
          onPressed: () => _showLicensePage(context),
          icon: const Icon(Icons.description),
          label: Text(AppL10n.tr(AppTranslationKeys.viewLicenses)),
        ),
      ],
    );
  }

  /// Builds a generic section card with consistent styling.
  Widget _buildSectionCard({
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Constants.aboutPagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  /// Builds the version information section displaying app version,
  /// build number, and package name.
  Widget _buildVersionInfo(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return _buildSectionCard(
      children: <Widget>[
        Text(
          AppL10n.tr(AppTranslationKeys.versionInformation),
          style: textTheme.titleLarge,
        ),
        const SizedBox(height: Constants.aboutVersionSpacing),
        _buildInfoRow(
          textTheme.bodyMedium,
          AppL10n.tr(AppTranslationKeys.versionLabel),
          GeneratedAppVersionData.version,
        ),
        _buildInfoRow(
          textTheme.bodyMedium,
          AppL10n.tr(AppTranslationKeys.buildNumberLabel),
          GeneratedAppVersionData.buildNumber,
        ),
        _buildInfoRow(
          textTheme.bodyMedium,
          AppL10n.tr(AppTranslationKeys.packageNameLabel),
          GeneratedAppVersionData.packageName,
        ),
      ],
    );
  }

  /// Display the 3rd party dependencies
  void _showLicensePage(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: AppL10n.tr(AppTranslationKeys.appName),
      applicationVersion: GeneratedAppVersionData.version,
      applicationIcon: Image.asset(
        _appIconAssetPath,
        width: Constants.aboutLicenseIconSize,
        height: Constants.aboutLicenseIconSize,
      ),
      applicationLegalese: AppL10n.tr(AppTranslationKeys.appCopyright),
    );
  }
}
