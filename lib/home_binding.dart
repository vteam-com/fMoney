import 'package:get/get.dart';

import 'helpers/home_controller.dart';

/// Represents home binding.
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
