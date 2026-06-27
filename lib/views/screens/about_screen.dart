import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/generated_app_version_data.dart';

const String _appIconAssetPath = 'assets/main_icon.png';

/// A page displaying app version information and licenses.
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
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
            _buildAppInfo(),
            const SizedBox(height: Constants.aboutSectionSpacing),
            _buildVersionInfo(),
            const SizedBox(height: Constants.aboutSectionSpacing),
            _buildLicenseSection(),
          ],
        ),
      ),
    );
  }

  /// Builds the app information section displaying the app name,
  /// description, and long description in a styled card.
  Widget _buildAppInfo() {
    return _buildSectionCard(
      children: <Widget>[
        Text(
          AppL10n.tr(AppTranslationKeys.appName),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: Constants.aboutIconSize),
        Text(
          AppL10n.tr(AppTranslationKeys.appDescription),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: Constants.aboutIconSize),
        Text(
          AppL10n.tr(AppTranslationKeys.appLongDescription),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  /// Builds a row displaying a label-value pair with consistent styling.
  /// Used in the version information section to show version details.
  ///
  /// Parameters:
  /// - [label]: The label text (e.g., "Version", "Build Number")
  /// - [value]: The corresponding value to display
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Constants.aboutInfoRowSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: Constants.aboutInfoLabelWidth,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the licenses section with license information
  /// and a button to view detailed licenses for all dependencies.
  Widget _buildLicenseSection() {
    return _buildSectionCard(
      children: <Widget>[
        Text(
          AppL10n.tr(AppTranslationKeys.licenses),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: Constants.aboutVersionSpacing),
        Text(
          AppL10n.tr(AppTranslationKeys.licensesDescription),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: Constants.aboutSectionSpacing),
        ElevatedButton.icon(
          onPressed: _showLicensePage,
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
  Widget _buildVersionInfo() {
    return _buildSectionCard(
      children: <Widget>[
        Text(
          AppL10n.tr(AppTranslationKeys.versionInformation),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: Constants.aboutVersionSpacing),
        _buildInfoRow(AppL10n.tr(AppTranslationKeys.versionLabel), GeneratedAppVersionData.version),
        _buildInfoRow(
          AppL10n.tr(AppTranslationKeys.buildNumberLabel),
          GeneratedAppVersionData.buildNumber,
        ),
        _buildInfoRow(
          AppL10n.tr(AppTranslationKeys.packageNameLabel),
          GeneratedAppVersionData.packageName,
        ),
      ],
    );
  }

  /// Dislay the 3rd party dependencies
  void _showLicensePage() {
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
