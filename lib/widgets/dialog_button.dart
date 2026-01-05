import 'package:flutter/material.dart';
import 'package:money/widgets/gaps.dart';

export 'package:flutter/material.dart';

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
                Opacity(opacity: 0.5, child: Icon(icon)),
                gapSmall(),
                Text(text),
              ],
            ),
          );
    return OutlinedButton(onPressed: onPressed, child: child);
  }
}
