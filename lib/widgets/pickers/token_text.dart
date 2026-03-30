// ignore: fcheck_one_class_per_file
import 'package:flutter/material.dart';
import 'package:money/helpers/constants.dart';

const double _tokenTextOpacity = 0.8;
const double _separatorOpacity = 0.6;

/// A stateless widget for token text.
class TokenText extends StatelessWidget {
  const TokenText(this.text, {super.key, this.style = const TokenTextStyle()});

  final TokenTextStyle style;

  final String text;

  @override
  Widget build(BuildContext context) {
    final List<String> tokens = text.split(style.separator);
    const TextStyle ancestors = TextStyle(fontSize: SizeForText.small);

    final Widget separator = Padding(
      padding: EdgeInsets.only(
        left: style.separatorPaddingLeft,
        right: style.separatorPaddingRight,
      ),
      child: Text(style.separator, style: ancestors),
    );

    final List<Widget> widgets = <Widget>[];

    for (final String token in tokens) {
      if (token == tokens.last) {
        widgets.add(
          Expanded(
            child: Text(
              token,
              softWrap: false,
              style: const TextStyle(fontSize: SizeForText.medium),
            ),
          ),
        );
      } else {
        widgets.add(
          Opacity(
            opacity: _tokenTextOpacity,
            child: Text(token, style: ancestors),
          ),
        );
        widgets.add(Opacity(opacity: _separatorOpacity, child: separator));
      }
    }

    return IntrinsicWidth(
      child: Row(mainAxisAlignment: MainAxisAlignment.start, children: widgets),
    );
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return text;
  }
}

/// Represents token text style.
class TokenTextStyle {
  const TokenTextStyle({
    this.separator = ':',
    this.separatorPaddingLeft = 0,
    this.separatorPaddingRight = SizeForPadding.small,
    this.rightAlign = false,
  });

  final bool rightAlign;
  final String separator;
  final double separatorPaddingLeft;
  final double separatorPaddingRight;
}
