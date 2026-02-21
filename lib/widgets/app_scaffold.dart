import 'package:flutter/material.dart';
import 'package:money/widgets/preferences_controller.dart';

// Exports
export 'package:flutter/material.dart';

/// Builds the app scaffold with global text scaling applied.
Widget myScaffold(
  final BuildContext context,
  final PreferredSizeWidget? appBar,
  final Widget body,
) {
  final MediaQueryData data = MediaQuery.of(
    context,
  ).copyWith(textScaler: TextScaler.linear(PreferenceController.to.textScale));
  return MediaQuery(
    data: data,
    child: Scaffold(appBar: appBar, body: body),
  );
}
