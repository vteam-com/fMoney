import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';

export 'package:flutter/material.dart';

/// A stateless widget for my list item as card.
class MyListItemAsCard extends StatelessWidget {
  /// Constructor
  const MyListItemAsCard({
    super.key,
    // Left
    //       Top
    //            String
    this.leftTopAsString,
    //            Widget
    this.leftTopAsWidget,

    //       Bottom
    //            String
    this.leftBottomAsString,
    //            Widget
    this.leftBottomAsWidget,

    // Right
    //       Top
    //            String
    this.rightTopAsString,
    //            Widget
    this.rightTopAsWidget,

    //       Bottom
    //            String
    this.rightBottomAsString,
    //       Bottom
    //            Widget
    this.rightBottomAsWidget,
    //
    this.bottomBorder = true,
  });

  final bool bottomBorder;
  final String? leftBottomAsString;
  final Widget? leftBottomAsWidget;
  final String? leftTopAsString;
  final Widget? leftTopAsWidget;
  final String? rightBottomAsString;
  final Widget? rightBottomAsWidget;
  final String? rightTopAsString;
  final Widget? rightTopAsWidget;

  @override
  Widget build(final BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              either(
                leftTopAsWidget,
                leftTopAsString,
                Theme.of(context).textTheme.titleMedium,
                TextAlign.left,
              ),
              either(
                leftBottomAsWidget,
                leftBottomAsString,
                adjustOpacityOfTextStyle(
                  Theme.of(context).textTheme.bodyMedium!,
                ),
                TextAlign.left,
              ),
            ],
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            either(
              rightTopAsWidget,
              rightTopAsString,
              Theme.of(context).textTheme.titleLarge,
              TextAlign.right,
            ),
            either(
              rightBottomAsWidget,
              rightBottomAsString,
              adjustOpacityOfTextStyle(Theme.of(context).textTheme.bodyMedium!),
              TextAlign.right,
            ),
          ],
        ),
      ],
    );
  }

  /// Returns widget [a] if condition is true, otherwise returns [b].
  Widget either(
    final Widget? a,
    final String? b,
    final TextStyle? style,
    final TextAlign? align,
  ) {
    if (a != null) {
      return a;
    }
    if (b != null) {
      return AnimatedOpacity(
        duration: const Duration(milliseconds: DurationInMs.slow),
        opacity: 1,
        child: Text(
          b,
          overflow: TextOverflow.ellipsis,
          style: style,
          textAlign: align,
        ),
      );
    }
    return const Text('');
  }
}
