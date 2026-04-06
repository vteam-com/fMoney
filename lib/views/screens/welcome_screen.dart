import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/presentation/helpers/mru_dropdown_widget.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/widgets/components/app_scaffold_widget.dart';
import 'package:money/widgets/components/text_title_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';

const double _welcomeTextFontSize = 16.0;
const double _welcomeButtonSpacing = 10.0;
const double _footerOpacity = 0.5;

/// Represents the welcome page of the fMoney application.
///
/// This page is the initial screen displayed when the user launches the app. It
/// includes an app bar with the title AppL10n.tr(AppTranslationKeys.welcomeToFmoney) and
/// the welcome content with actions for starting a new file, opening an existing
/// file, or loading demo data. The [WelcomePage] shows the app's startup actions.
class WelcomePage extends StatelessWidget {
  /// Constructs a [WelcomePage] widget with the provided [key].
  const WelcomePage({super.key});

  /// Builds the welcome page scaffold.
  @override
  Widget build(BuildContext context) {
    return myScaffold(
      context,
      AppBar(title: TextTitle(AppL10n.tr(AppTranslationKeys.welcomeToFmoney)), centerTitle: true),
      _buildWelcomeContent(context),
    );
  }

  /// Builds the column of welcome actions shown below the app bar.
  Widget _buildWelcomeContent(final BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Spacer(),
          Text(
            AppL10n.tr(AppTranslationKeys.chooseAnOptionToGetStarted),
            style: const TextStyle(fontSize: _welcomeTextFontSize),
          ),
          gapLarge(),
          Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: _welcomeButtonSpacing,
            runSpacing: _welcomeButtonSpacing,
            children: <Widget>[
              OutlinedButton(
                onPressed: () {
                  DataFileController.to.onFileNew();
                  AppRouter.pushNamedAndRemoveUntil<dynamic>(Constants.routeHomePage);
                },
                child: Text(AppL10n.tr(AppTranslationKeys.newFile)),
              ),
              OutlinedButton(
                onPressed: () async {
                  final bool succeeded = await DataFileController.to.onFileOpen();
                  if (succeeded) {
                    AppRouter.pushNamedAndRemoveUntil<dynamic>(Constants.routeHomePage);
                  }
                },
                child: Text(AppL10n.tr(AppTranslationKeys.openFile)),
              ),
              OutlinedButton(
                onPressed: () async {
                  DataFileController.to.closeFile();
                  await DataFileController.to.loadDemoData();
                  AppRouter.pushNamedAndRemoveUntil<dynamic>(Constants.routeHomePage);
                },
                child: Text(AppL10n.tr(AppTranslationKeys.useDemoData)),
              ),
            ],
          ),
          gapLarge(),
          const MruDropdown(),
          const Spacer(),
          IntrinsicWidth(
            child: Opacity(
              opacity: _footerOpacity,
              child: Row(
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      AppRouter.pushNamed<dynamic>(Constants.routePolicyPage);
                    },
                    child: Text(AppL10n.tr(AppTranslationKeys.privacyPolicy)),
                  ),
                  gapLarge(),
                  TextButton(
                    onPressed: () {
                      showLicensePage(context: context);
                    },
                    child: Text(AppL10n.tr(AppTranslationKeys.licenses)),
                  ),
                ],
              ),
            ),
          ),
          gapLarge(),
        ],
      ),
    );
  }
}
