import 'package:get/get.dart';
import 'package:money/constants.dart';

import 'welcome_binding.dart';
import 'welcome_page.dart';

/// Defines the routes for the welcome page in the application.
/// The [WelcomeRoutes] class is a utility class that holds the
/// route definitions for the welcome page. It includes a single
/// route for the [WelcomePage] which is bound to the [WelcomeBinding].
class WelcomeRoutes {
  WelcomeRoutes._();

  /// Defines a single route for the WelcomePage, which is bound to the WelcomeBinding.
  /// The route is defined using the GetPage class from the get_x package, and uses the
  /// Constants.routeWelcomePage constant as the name of the route.
  static final List<GetPage<dynamic>> routes = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: Constants.routeWelcomePage,
      page: () => const WelcomePage(),
      binding: WelcomeBinding(),
    ),
  ];
}
