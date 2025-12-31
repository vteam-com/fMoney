import 'package:money/constants.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/widgets/dialog/dialog_button.dart';
import 'package:money/widgets/dialog/dialog_full_screen.dart';
import 'package:money/widgets/misc_widgets.dart';

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
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        side: BorderSide(
          color: getColorTheme(context).primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      content: Container(
        constraints: const BoxConstraints(
          minHeight: 500,
          maxHeight: 1000,
          minWidth: 500,
          maxWidth: 1000,
        ),
        child: child,
      ),
      actions: actions,
    );
  }
}

void adaptiveScreenSizeDialog({
  required final BuildContext context,
  final String title = '',
  required final Widget child,
  List<Widget>? actionButtons,
  final String? captionForClose = 'Close',
}) {
  actionButtons ??= <Widget>[];

  // in modal always offer a close button
  if (captionForClose != null) {
    // Cancel and close are inserted on the left side of other buttons
    // so place it first on the list
    actionButtons.insert(
      0,
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
      builder: (BuildContext context) {
        return FullScreenDialog(
          title: title,
          content: Padding(padding: const EdgeInsets.all(8.0), child: child),
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
    builder: (final BuildContext context) {
      return MyAlertDialog(
        title: title,
        scrollable: true,
        actions: actionButtons,
        child: child,
      );
    },
  );
}
