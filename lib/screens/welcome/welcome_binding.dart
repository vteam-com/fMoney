import 'package:get/get.dart';

import 'welcome_controller.dart';

/// Represents welcome binding.
class WelcomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WelcomeController>(() => WelcomeController());
  }
}
