import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/widgets/pure/box_widget.dart';

const double _messageBoxWidth = 400;
const double _messageBoxHeight = 60;

/// a basic text that is centered in the parent container
class CenterMessage extends StatelessWidget {
  /// constructor
  const CenterMessage({required this.message, this.child, super.key});

  factory CenterMessage.noItems() => CenterMessage(message: AppL10n.tr(AppTranslationKeys.noItems));

  factory CenterMessage.noTransaction() => CenterMessage(message: AppL10n.tr(AppTranslationKeys.noTransactionsPeriod));

  final Widget? child;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
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
