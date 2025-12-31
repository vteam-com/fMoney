import 'package:get/get.dart';
import 'package:money/constants.dart';
import 'package:money/views/policies/policy_page.dart';

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
