import 'package:flutter/material.dart';
import 'package:money/widgets/scale_down.dart';

class DialogAutoSize extends StatelessWidget {
  const DialogAutoSize({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    ShapeBorder? dialogShape;
    EdgeInsets? insetPadding;

    if (context.isWidthSmall) {
      insetPadding = EdgeInsets.zero;
    } else {
      dialogShape = RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        side: BorderSide(
          width: 2.0, // Adjust border width as needed
          color: Theme.of(
            context,
          ).dividerColor, // Set your desired border color here
        ),
      );
      insetPadding = const EdgeInsets.symmetric(
        horizontal: 40.0,
        vertical: 24.0,
      );
    }

    return Dialog(
      shape: dialogShape,
      insetPadding: insetPadding,
      // Set elevation to 0 to remove default shadow
      elevation: 0.0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(padding: const EdgeInsets.all(16.0), child: child),
      ),
    );
  }
}
