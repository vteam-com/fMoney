import 'package:flutter/material.dart';
import 'package:money/widgets/pure/gaps_helper.dart';

export 'package:flutter/material.dart';

const double _iconOpacity = 0.5;

/// A stateless widget for dialog action button.
class DialogActionButton extends StatelessWidget {
  const DialogActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  final IconData? icon;
  final VoidCallback onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    final Widget child = icon == null
        ? Text(text)
        : IntrinsicWidth(
            child: Row(
              children: <Widget>[
                Opacity(opacity: _iconOpacity, child: Icon(icon)),
                gapSmall(),
                Text(text),
              ],
            ),
          );
    return OutlinedButton(onPressed: onPressed, child: child);
  }
}
