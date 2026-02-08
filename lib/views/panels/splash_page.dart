import 'package:flutter/material.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/text_title.dart';

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
              const TextTitle('fMoney'),
              gapHuge(),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
