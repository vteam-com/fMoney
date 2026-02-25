import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:url_launcher/url_launcher.dart';

const double _platformsPageWidth = 400.0;
const double _sectionSpacing = 40.0;
const int _platformButtonElevation = 9;
const double _platformButtonPadding = 20.0;
const double _platformRowSpacing = 20.0;
const double _platformNameFontSize = 20.0;
const double _platformDescriptionOpacity = 0.8;

/// A stateless widget for platforms page.
class PlatformsPage extends StatelessWidget {
  const PlatformsPage({super.key});

  @override
  Widget build(final BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppL10n.tr(AppTranslationKeys.availableOn))),
    body: Center(
      child: SizedBox(
        width: _platformsPageWidth,
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              paltformItem(
                'macOS',
                'assets/images/platforms/platformDesktopMacOS.png',
                'Desktop Intel & Silicon Software.',
                'https://money.vteam.com/downloads/mymoney-app-macos.zip',
              ),
              paltformItem(
                'Windows',
                'assets/images/platforms/platformDesktopWindows.png',
                'Desktop 64bit Software.',
                'https://money.vteam.com/downloads/mymoney-app-windows.zip',
              ),
              paltformItem(
                'Linux',
                'assets/images/platforms/platformDesktopLinux.png',
                'Desktop Software.',
                'https://money.vteam.com/downloads/mymoney-app-linux.zip',
              ),
              const SizedBox(height: _sectionSpacing),
              paltformItem(
                'iOS',
                'assets/images/platforms/platformMobileIOS.png',
                'Mobile app.',
                'https://apps.apple.com/us/app/cooking-timer-by-vteam/id1188460815',
              ),
              paltformItem(
                'Android',
                'assets/images/platforms/platformMobileAndroid.png',
                'Mobile app.',
                'https://play.google.com/store/apps/details?id=com.vteam.cookingtimerflutter',
              ),
              const SizedBox(height: _sectionSpacing),
              paltformItem(
                'Web Browser',
                'assets/images/platforms/platformWeb.png',
                'Run on any OS with most browsers.',
                'https://money.vteam.com',
              ),
            ],
          ),
        ),
      ),
    ),
  );

  /// Builds a platform item widget with name, image, description, and URL.
  Widget paltformItem(
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
      spacing: _platformRowSpacing,
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
