import 'package:flutter/material.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/widgets/box.dart';

const double _messageBoxWidth = 400;
const double _messageBoxHeight = 60;

/// a basic text that is centered in the parent container
class CenterMessage extends StatelessWidget {
  /// constructor
  const CenterMessage({required this.message, this.child, super.key});

  factory CenterMessage.noItems() => const CenterMessage(message: 'No items');

  factory CenterMessage.noTransaction() => const CenterMessage(message: 'No transactions.');

  final Widget? child;
  final String message;

  @override
  Widget build(final BuildContext context) => Center(
    child: Box(
      width: _messageBoxWidth,
      height: _messageBoxHeight,
      child: Center(
        child: IntrinsicWidth(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(child: Text(message)),
              if (child != null)
                Padding(
                  padding: const EdgeInsets.only(left: SizeForPadding.huge),
                  child: child!,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
