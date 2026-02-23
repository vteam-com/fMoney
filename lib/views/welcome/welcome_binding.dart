import 'package:get/get.dart';
import 'package:money/views/welcome/welcome_controller.dart';

/// Represents welcome binding.
class WelcomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WelcomeController>(() => WelcomeController());
  }
}
