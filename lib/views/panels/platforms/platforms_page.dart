import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/services/github_artifacts_service.dart';
import 'package:url_launcher/url_launcher.dart';

const double _platformsPageWidth = 400.0;
const double _sectionSpacing = 40.0;
const int _platformButtonElevation = 9;
const double _platformButtonPadding = 20.0;
const double _platformNameFontSize = 20.0;
const double _platformDescriptionOpacity = 0.8;

/// A stateless widget for platforms page.
class PlatformsPage extends StatefulWidget {
  const PlatformsPage({super.key});

  @override
  State<PlatformsPage> createState() => _PlatformsPageState();
}

class _PlatformsPageState extends State<PlatformsPage> {
  late Future<Map<String, String>> _artifactUrlsFuture;

  @override
  void initState() {
    super.initState();
    _artifactUrlsFuture = GitHubArtifactsService.getLatestArtifactUrls();
  }

  @override
  Widget build(final BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppL10n.tr(AppTranslationKeys.availableOn))),
    body: Center(
      child: SizedBox(
        width: _platformsPageWidth,
        child: SingleChildScrollView(
          child: FutureBuilder<Map<String, String>>(
            future: _artifactUrlsFuture,
            builder: (BuildContext _, AsyncSnapshot<Map<String, String>> snapshot) {
              final Map<String, String> artifactUrls = snapshot.data ?? <String, String>{};

              return Column(
                children: <Widget>[
                  _buildPlatformItem(
                    'macOS',
                    'assets/images/platforms/platformDesktopMacOS.png',
                    'Desktop Intel & Silicon Software.',
                    artifactUrls['macos'] ?? 'https://money.vteam.com/downloads/mymoney-app-macos.zip',
                  ),
                  _buildPlatformItem(
                    'Windows',
                    'assets/images/platforms/platformDesktopWindows.png',
                    'Desktop 64bit Software.',
                    artifactUrls['windows'] ?? 'https://money.vteam.com/downloads/mymoney-app-windows.zip',
                  ),
                  _buildPlatformItem(
                    'Linux',
                    'assets/images/platforms/platformDesktopLinux.png',
                    'Desktop Software.',
                    artifactUrls['linux'] ?? 'https://money.vteam.com/downloads/mymoney-app-linux.zip',
                  ),
                  const SizedBox(height: _sectionSpacing),
                  _buildPlatformItem(
                    'iOS',
                    'assets/images/platforms/platformMobileIOS.png',
                    'Mobile app.',
                    'https://apps.apple.com/us/app/cooking-timer-by-vteam/id1188460815',
                  ),
                  _buildPlatformItem(
                    'Android',
                    'assets/images/platforms/platformMobileAndroid.png',
                    'Mobile app.',
                    'https://play.google.com/store/apps/details?id=com.vteam.cookingtimerflutter',
                  ),
                  const SizedBox(height: _sectionSpacing),
                  _buildPlatformItem(
                    'Web Browser',
                    'assets/images/platforms/platformWeb.png',
                    'Run on any OS with most browsers.',
                    'https://money.vteam.com',
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.all(Constants.loadingPadding),
                      child: CircularProgressIndicator(),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );

  /// Builds a platform item widget with name, image, description, and URL.
  Widget _buildPlatformItem(
    final String name,
    final String image,
    final String description,
    final String url,
  ) => MaterialButton(
    key: ValueKey<String>(name),
    elevation: _platformButtonElevation.toDouble(),
    padding: const EdgeInsets.all(_platformButtonPadding),
    onPressed: () {
      launchUrl(Uri.parse(url));
    },
    child: Row(
      spacing: Constants.loadingPadding,
      children: <Widget>[
        CircleAvatar(
          backgroundColor: Colors.white,
          foregroundImage: AssetImage(image),
        ),
        Expanded(
          child: Text(name, style: const TextStyle(fontSize: _platformNameFontSize)),
        ),
        Expanded(
          child: Opacity(opacity: _platformDescriptionOpacity, child: Text(description)),
        ),
      ],
    ),
  );
}
