import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/views/pages/view_welcome.dart';
import 'package:money/widgets/components/app_scaffold.dart';
import 'package:money/widgets/components/text_title.dart';

/// Represents the welcome page of the fMoney application.
///
/// This page is the initial screen displayed when the user launches the app. It
/// includes an app bar with the title AppL10n.tr(AppTranslationKeys.welcomeToFmoney) and a [WelcomeScreen]
/// widget that displays the welcome content.
///
/// The [WelcomePage] shows the app's startup actions.
class WelcomePage extends StatelessWidget {
  /// Constructs a [WelcomePage] widget with the provided [key].
  const WelcomePage({super.key});

  /// Builds the welcome page scaffold.
  @override
  Widget build(BuildContext context) {
    return myScaffold(
      context,
      AppBar(title: TextTitle(AppL10n.tr(AppTranslationKeys.welcomeToFmoney)), centerTitle: true),
      const WelcomeScreen(),
    );
  }
}
