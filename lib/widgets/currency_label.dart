import 'package:flutter/material.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/scale_down.dart';

const double _flagHeight = 10;

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
            if (flagId.isNotEmpty) Image.asset('assets/flags/$flagId.png', height: _flagHeight),
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
