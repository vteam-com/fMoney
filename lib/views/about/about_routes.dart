import 'package:get/get.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/views/about/about_page.dart';

/// Defines the routes for the about page in the application.
class AboutRoutes {
  AboutRoutes._();

  /// Defines the routes for the about page in the application.
  /// This includes a single route for the AboutPage.
  static final List<GetPage<dynamic>> routes = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: Constants.routeAboutPage,
      page: () => const AboutPage(),
    ),
  ];
}
