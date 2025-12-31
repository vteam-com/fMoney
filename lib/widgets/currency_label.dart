import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/misc_widgets.dart';

// Exports
export 'package:flutter/material.dart';
export 'package:money/widgets/misc_widgets.dart';
export 'package:money/widgets/value_widgets.dart';

class CurrencyLabel extends StatelessWidget {
  const CurrencyLabel({
    required this.threeLetterCurrencySymbol,
    required this.flagId,
    super.key,
  });

  final String flagId;

  final String threeLetterCurrencySymbol;

  @override
  Widget build(BuildContext context) {
    return scaleDown(
      Semantics(
        label: threeLetterCurrencySymbol,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(threeLetterCurrencySymbol),
            gapSmall(),
            if (flagId.isNotEmpty) Image.asset('assets/flags/$flagId.png', height: 10),
          ],
        ),
      ),
    );
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) {
    return '$threeLetterCurrencySymbol:$flagId';
  }
}
