import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/dialogs/dialog_full_screen.dart';
import 'package:money/widgets/pure/scale_down_widget.dart';

const double _dialogBorderRadius = 8;
const double _dialogBorderAlpha = 0.3;
const double _dialogBorderWidth = 1;
const double _dialogMinSize = 500;
const double _dialogMaxSize = 1000;
const double _fullScreenPadding = 8;
const int _actionButtonInsertIndex = 0;

/// A stateless widget for my alert dialog.
class MyAlertDialog extends StatelessWidget {
  const MyAlertDialog({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.actions,
    this.scrollable = false,
  });

  final List<Widget>? actions;
  final Widget child;
  final IconData? icon;
  final bool scrollable;
  final String title;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title.isEmpty ? null : Text(title),
      icon: icon == null ? null : Icon(icon!),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(_dialogBorderRadius),
        ),
        side: BorderSide(
          color: getColorTheme(
            context,
          ).primary.withValues(alpha: _dialogBorderAlpha),
          width: _dialogBorderWidth,
        ),
      ),
      content: Container(
        constraints: const BoxConstraints(
          minHeight: _dialogMinSize,
          maxHeight: _dialogMaxSize,
          minWidth: _dialogMinSize,
          maxWidth: _dialogMaxSize,
        ),
        child: child,
      ),
      actions: actions,
    );
  }
}

/// Shows a responsive dialog with adaptive sizing and optional actions.
void adaptiveScreenSizeDialog({
  required final BuildContext context,
  final String title = '',
  required final Widget child,
  List<Widget>? actionButtons,
  final String? captionForClose = SharedStrings.labelClose,
}) {
  actionButtons ??= <Widget>[];

  // in modal always offer a close button
  if (captionForClose != null) {
    // Cancel and close are inserted on the left side of other buttons
    // so place it first on the list
    actionButtons.insert(
      _actionButtonInsertIndex,
      DialogActionButton(
        key: Constants.keyButtonCancel,
        text: captionForClose,
        onPressed: () {
          Navigator.of(context).pop(false);
        },
      ),
    );
  }

  if (context.isWidthSmall) {
    // Full screen also comes with a Close (X) button
    showDialog<dynamic>(
      context: context,
      builder: (BuildContext _) {
        return FullScreenDialog(
          title: title,
          content: Padding(
            padding: const EdgeInsets.all(_fullScreenPadding),
            child: child,
          ),
          actionButtons: actionButtons ?? <Widget>[],
        );
      },
    );
    return;
  }

  // Large screen
  showDialog<dynamic>(
    context: context,
    barrierDismissible: false,
    builder: (final BuildContext _) {
      return MyAlertDialog(
        title: title,
        scrollable: true,
        actions: actionButtons,
        child: child,
      );
    },
  );
}
