import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PlatformsPage extends StatelessWidget {
  const PlatformsPage({super.key});

  @override
  Widget build(final BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Available on')),
    body: Center(
      child: SizedBox(
        width: 400,
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
              const SizedBox(height: 40),
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
              const SizedBox(height: 40),
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

  Widget paltformItem(
    final String name,
    final String image,
    final String description,
    final String url,
  ) => MaterialButton(
    key: ValueKey<String>(name),
    elevation: 9,
    padding: const EdgeInsets.all(20),
    onPressed: () {
      launchUrl(Uri.parse(url));
    },
    child: Row(
      spacing: 20,
      children: <Widget>[
        CircleAvatar(
          backgroundColor: Colors.white,
          foregroundImage: AssetImage(image),
        ),
        Expanded(child: Text(name, style: const TextStyle(fontSize: 20))),
        Expanded(child: Opacity(opacity: 0.8, child: Text(description))),
      ],
    ),
  );
}
