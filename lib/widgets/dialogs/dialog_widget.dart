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
const double _fullScreenPadding = SizeForPadding.normal;
const double _dialogOuterPadding = 24;
const double _dialogInnerTopPadding = 16;
const int _actionButtonInsertIndex = 0;

/// A stateless widget for my alert dialog.
///
/// Uses [Dialog] (not [AlertDialog]) to avoid the framework-imposed
/// [IntrinsicWidth] wrapper that [AlertDialog] always applies. That wrapper
/// breaks any descendant that cannot provide intrinsic dimensions, such as
/// [ListView] ([RenderViewport]) or [LayoutBuilder].
class MyAlertDialog extends StatelessWidget {
  const MyAlertDialog({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.actions,
  });

  final List<Widget>? actions;
  final Widget child;
  final IconData? icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(_dialogBorderRadius),
        ),
        side: BorderSide(
          color: getColorTheme(context).primary.withValues(alpha: _dialogBorderAlpha),
          width: _dialogBorderWidth,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: _dialogMinSize,
          maxWidth: _dialogMaxSize,
          maxHeight: _dialogMaxSize,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (title.isNotEmpty || icon != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(_dialogOuterPadding, _dialogOuterPadding, _dialogOuterPadding, 0),
                child: icon != null ? Icon(icon) : Text(title, style: Theme.of(context).textTheme.headlineSmall),
              ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  _dialogOuterPadding,
                  _dialogInnerTopPadding,
                  _dialogOuterPadding,
                  _dialogOuterPadding,
                ),
                child: child,
              ),
            ),
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SizeForPadding.normal,
                  0,
                  SizeForPadding.normal,
                  SizeForPadding.normal,
                ),
                child: OverflowBar(
                  alignment: MainAxisAlignment.end,
                  spacing: SizeForPadding.normal,
                  children: actions!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shows a responsive dialog with adaptive sizing and optional actions.
void adaptiveScreenSizeDialog({
  required BuildContext context,
  String title = '',
  required Widget child,
  List<Widget>? actionButtons,
  String? captionForClose = SharedStrings.labelClose,
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
    builder: (BuildContext _) {
      return MyAlertDialog(
        title: title,
        actions: actionButtons,
        child: child,
      );
    },
  );
}
