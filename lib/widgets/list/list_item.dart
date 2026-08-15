import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:money/helpers/color_helper.dart';

// Exports
export 'package:flutter/material.dart';
export 'package:money/widgets/pure/scale_down_widget.dart';

const double _hoveredBackgroundAlpha = 0.3;
const double _rowDividerWidth = 0.5;
const double _rowDividerAlpha = 0.3;
const double _adornmentWidth = 2;
const double _adornmentCapThickness = 3;

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
    this.rightAdornmentColor = Colors.transparent,
    this.showRightAdornmentTopCap = false,
    this.showRightAdornmentBottomCap = false,
  });
  final Color adornmentColor;
  final bool autoFocus;
  final Widget child;
  final bool isSelected;
  final GestureTapCallback? onDoubleTap;
  final KeyEventResult Function(FocusNode, KeyEvent) onListViewKeyEvent;
  final GestureTapCallback? onLongPress;
  final GestureTapCallback? onTap;
  final Color rightAdornmentColor;
  final bool showRightAdornmentBottomCap;
  final bool showRightAdornmentTopCap;
  @override
  State<MyListItem> createState() => MyListItemState();
}

/// State for my list item.
class MyListItemState extends State<MyListItem> {
  bool _hovering = false;

  bool isSelected = false;

  @override
  void initState() {
    super.initState();
    isSelected = widget.isSelected;
  }

  @override
  void didUpdateWidget(MyListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    isSelected = widget.isSelected;
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isSelected
        ? getColorTheme(context).primaryContainer
        : _hovering
        ? getColorTheme(context).inversePrimary.withValues(
            alpha: _hoveredBackgroundAlpha,
          )
        : Colors.transparent;

    return ExcludeFocus(
      excluding: kIsWeb,
      child: Focus(
        autofocus: !kIsWeb && widget.autoFocus,
        canRequestFocus: !kIsWeb,
        skipTraversal: kIsWeb,
        onFocusChange: (bool value) {
          if (value) {}
        },
        onKeyEvent: widget.onListViewKeyEvent,
        child: MouseRegion(
          onHover: (PointerHoverEvent _) => setState(() => _hovering = true),
          onExit: (PointerExitEvent _) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: () {
              setState(() {
                isSelected = !isSelected;
              });
              widget.onTap?.call();
            },
            onDoubleTap: widget.onDoubleTap,
            onLongPress: widget.onLongPress,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                DecoratedBox(
                  // height: 40,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border(
                      top: BorderSide(
                        width: _rowDividerWidth,
                        color: getColorTheme(
                          context,
                        ).outline.withValues(alpha: _rowDividerAlpha),
                      ),
                      left: BorderSide(
                        width: _adornmentWidth,
                        color: widget.adornmentColor,
                      ),
                      right: BorderSide(
                        width: _adornmentWidth,
                        color: widget.rightAdornmentColor,
                      ),
                      bottom: BorderSide(
                        width: _rowDividerWidth,
                        color: getColorTheme(
                          context,
                        ).outline.withValues(alpha: _rowDividerAlpha),
                      ),
                    ),
                  ),
                  child: widget.child,
                ),
                if (widget.showRightAdornmentTopCap)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ColoredBox(
                      color: widget.rightAdornmentColor,
                      child: const SizedBox(height: _adornmentCapThickness),
                    ),
                  ),
                if (widget.showRightAdornmentBottomCap)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ColoredBox(
                      color: widget.rightAdornmentColor,
                      child: const SizedBox(height: _adornmentCapThickness),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
