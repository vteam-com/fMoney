import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/widgets/components/text_title_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';

const double _splashHeight = 300.0;

/// The `SplashScreen` widget is a stateless widget that displays a simple splash screen
/// with the app title and a circular progress indicator. This screen is typically
/// shown when the app is first launched, while the app is initializing or loading
/// resources.
class SplashScreen extends StatelessWidget {
  /// Constructs a new instance of the `SplashScreen` widget.
  ///
  /// The `super.key` parameter is passed to the base class constructor.
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          height: _splashHeight,
          child: Column(
            children: <Widget>[
              TextTitle(AppL10n.tr(AppTranslationKeys.fmoney)),
              gapHuge(),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
