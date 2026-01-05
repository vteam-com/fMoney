import 'package:get/get.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/views/panels/platforms/platforms_page.dart';

/// Defines the routes for the settings page in the application.
class PlatformsRoutes {
  PlatformsRoutes._();

  /// Defines the routes for the settings page in the application.
  /// This includes a single route for the SettingsPage.
  static final List<GetPage<dynamic>> routes = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: Constants.routeInstallPlatformsPage,
      page: () => const PlatformsPage(),
    ),
  ];
}
