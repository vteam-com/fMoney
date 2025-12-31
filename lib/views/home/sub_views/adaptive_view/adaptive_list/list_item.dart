import 'package:flutter/services.dart';
import 'package:money/helpers/color_helper.dart';

// Exports
export 'package:money/widgets/widgets.dart';

/// A Row for a Table view
class MyListItem extends StatefulWidget {
  const MyListItem({
    required this.onListViewKeyEvent,
    required this.isSelected,
    required this.child,
    super.key,
    this.autoFocus = false,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.adornmentColor = Colors.transparent,
  });

  final Color adornmentColor;
  final bool autoFocus;
  final Widget child;
  final bool isSelected;
  final GestureTapCallback? onDoubleTap;
  final KeyEventResult Function(FocusNode, KeyEvent) onListViewKeyEvent;
  final GestureTapCallback? onLongPress;
  final GestureTapCallback? onTap;

  @override
  State<MyListItem> createState() => MyListItemState();
}

class MyListItemState extends State<MyListItem> {
  bool _hovering = false;

  bool isSelected = false;

  @override
  void initState() {
    super.initState();
    isSelected = widget.isSelected;
  }

  @override
  void didUpdateWidget(final MyListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    isSelected = widget.isSelected;
  }

  @override
  Widget build(final BuildContext context) {
    final Color backgroundColor = isSelected
        ? getColorTheme(context).primaryContainer
        : _hovering
        ? getColorTheme(context).inversePrimary.withValues(alpha: 0.3)
        : Colors.transparent;

    return Focus(
      autofocus: widget.autoFocus,
      onFocusChange: (final bool value) {
        if (value) {}
      },
      onKeyEvent: widget.onListViewKeyEvent,
      child: MouseRegion(
        onHover: (PointerHoverEvent event) => setState(() => _hovering = true),
        onExit: (PointerExitEvent event) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: () {
            setState(() {
              isSelected = !isSelected;
            });
            widget.onTap?.call();
          },
          onDoubleTap: widget.onDoubleTap,
          onLongPress: widget.onLongPress,
          child: DecoratedBox(
            // height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                top: BorderSide(
                  width: 0.5,
                  color: getColorTheme(context).outline.withValues(alpha: 0.3),
                ),
                left: BorderSide(width: 2, color: widget.adornmentColor),
                bottom: BorderSide(
                  width: 0.5,
                  color: getColorTheme(context).outline.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
