import 'package:get/get.dart';
import 'package:money/views/welcome/view_welcome.dart';
import 'package:money/widgets/app_scaffold.dart';
import 'package:money/widgets/text_title.dart';

import 'welcome_controller.dart';

/// Represents the welcome page of the fMoney application.
///
/// This page is the initial screen displayed when the user launches the app. It
/// includes an app bar with the title "Welcome to fMoney" and a [WelcomeScreen]
/// widget that displays the welcome content.
///
/// The [WelcomePage] is a [GetView] that uses the [WelcomeController] to manage
/// the state and logic of the welcome screen.
class WelcomePage extends GetView<WelcomeController> {
  /// Constructs a [WelcomePage] widget with the provided [key].
  const WelcomePage({super.key});

  /// Builds the welcome page scaffold.
  @override
  Widget build(BuildContext context) {
    return myScaffold(
      context,
      AppBar(title: const TextTitle('Welcome to fMoney'), centerTitle: true),
      const WelcomeScreen(),
    );
  }
}
