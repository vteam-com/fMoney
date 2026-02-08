import 'package:flutter/material.dart';
import 'package:money/widgets/scale_down.dart';

const double _dialogBorderRadius = 8;
const double _dialogBorderWidth = 2;
const double _dialogInsetHorizontal = 40;
const double _dialogInsetVertical = 24;
const double _dialogElevation = 0;
const double _dialogMaxWidth = 800;
const double _dialogPadding = 16;

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
        borderRadius: const BorderRadius.all(
          Radius.circular(_dialogBorderRadius),
        ),
        side: BorderSide(
          width: _dialogBorderWidth, // Adjust border width as needed
          color: Theme.of(
            context,
          ).dividerColor, // Set your desired border color here
        ),
      );
      insetPadding = const EdgeInsets.symmetric(
        horizontal: _dialogInsetHorizontal,
        vertical: _dialogInsetVertical,
      );
    }

    return Dialog(
      shape: dialogShape,
      insetPadding: insetPadding,
      // Set elevation to 0 to remove default shadow
      elevation: _dialogElevation,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _dialogMaxWidth),
        child: Padding(
          padding: const EdgeInsets.all(_dialogPadding),
          child: child,
        ),
      ),
    );
  }
}
