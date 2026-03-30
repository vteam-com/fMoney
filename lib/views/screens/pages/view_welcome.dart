import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_router.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/shared/presentation/mru_dropdown.dart';
import 'package:money/shared/presentation/provider_data_file_controller.dart';
import 'package:money/widgets/pure/gaps.dart';

const double _welcomeTextFontSize = 16.0;
const double _welcomeButtonSpacing = 10.0;
const double _footerOpacity = 0.5;

/// The `WelcomeScreen` is a `StatelessWidget` that represents the welcome screen of the application.
/// It provides the user with options to create a new file, open an existing file, or use demo data.
class WelcomeScreen extends StatelessWidget {
  /// Constructs a new instance of the `WelcomeScreen` widget.
  const WelcomeScreen({super.key});

  /// Builds the welcome screen UI and entry actions.
  @override
  Widget build(final BuildContext context) {
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
