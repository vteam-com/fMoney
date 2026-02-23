import 'package:get/get.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/views/panels/policies/policy_page.dart';

/// Represents policy routes.
class PolicyRoutes {
  PolicyRoutes._();

  static final List<GetPage<dynamic>> routes = <GetPage<dynamic>>[
    GetPage<dynamic>(
      name: Constants.routePolicyPage,
      page: () => const PolicyPage(),
      // binding: WelcomeBinding(),
    ),
  ];
}
