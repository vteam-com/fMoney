import 'package:flutter/material.dart';
import 'package:money/widgets/state/preferences_controller.dart';

// Exports
export 'package:flutter/material.dart';

/// Builds the app scaffold with global text scaling applied.
Widget myScaffold(
  BuildContext context,
  PreferredSizeWidget? appBar,
  Widget body,
) {
  final MediaQueryData data = MediaQuery.of(
    context,
  ).copyWith(textScaler: TextScaler.linear(PreferenceController.to.textScale));
  return MediaQuery(
    data: data,
    child: Scaffold(appBar: appBar, body: body),
  );
}
