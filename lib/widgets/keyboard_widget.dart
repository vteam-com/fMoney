import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// A keyMap widget allowing easy addition of shortcut keys to any widget tree
/// with an optional help screen overlay
class KeyboardWidget extends StatefulWidget {
  /// Creates a new KeyboardWidget with a list of Keystrokes and associated
  /// functions [bindings], a required [child] widget and an optional
  /// keystroke to show and dismiss the displayed map, [showDismissKey].
  ///
  /// The number of columns of text used to display the options can be optionally
  /// chosen. It defaults to one column.
  ///
  /// The [backgroundColor] and [textColor] set the background of the
  /// card used to display the help screen background and text respectively.
  /// Otherwise they default to the inherited theme's card and primary text
  /// colors.
  ///
  /// By default the F1 keyboard key is used to show and dismiss the keyMap
  /// display. If another key is preferred, set the [showDismissKey] to another
  /// [LogicalKeyboardKey].
  ///
  /// If the help map should be displayed, set the parameter [showMap] to true.
  /// This lets the implementer programmatically show the map.
  /// You would usually pair this with a function [callbackOnHide] so that the caller
  /// to show the help screen can be notified when it is hidden
  ///
  const KeyboardWidget({
    required this.bindings,
    required this.child,
    super.key,
    this.helpText,
    this.hasFocus = true,
    this.showDismissKey = LogicalKeyboardKey.f1,
    this.groupByCategory = false,
    this.columnCount = 1,
    this.backgroundColor,
    this.showLines = false,
    this.textStyle,
    this.showMap = false,
    this.callbackOnHide,
  }) : assert(columnCount > 0);

  ///The color of the surface of the card used to display a help screen.
  ///If null, the card color of the inherited [ThemeData.colorScheme] will be used
  final Color? backgroundColor;

  ///The list of keystrokes and methods called
  final List<KeyAction> bindings;

  final VoidCallback? callbackOnHide;

  final Widget child;

  ///The number of columns of text in the help screen
  final int columnCount;

  ///Have group the keybindings shown in the overlay grouped according to
  ///the (optional) headers associated with each shortcut
  final bool groupByCategory;

  final bool hasFocus;

  ///Optional introductory/descriptive text to include above the table of
  ///keystroke shortcuts. It expects text in the
  ///[https://daringfireball.net/projects/markdown/] markdown format, using
  ///the [https://pub.dev/packages/flutter_markdown] flutter markdown package.
  final String? helpText;

  ///The keystroke used to show and dismiss the help screen
  final LogicalKeyboardKey showDismissKey;

  ///Whether underlines should be shown between each help entry
  final bool showLines;

  final bool showMap;

  ///The text style for the text used in the help screen. If null, the
  ///inherited [TextTheme.labelSmall] is used.
  final TextStyle? textStyle;

  @override
  KeyboardWidgetState createState() => KeyboardWidgetState();
}

class KeyboardWidgetState extends State<KeyboardWidget> {
  late FocusNode _focusNode;

  late OverlayEntry _overlayEntry;

  static const Color defaultBackground = Color(0xFF0a0a0a);

  static const Color defaultTextColor = Colors.white;

  static const TextStyle defaultTextStyle = TextStyle(
    color: defaultTextColor,
    fontSize: 12,
  );

  static const double horizontalMargin = 16.0;

  bool isKeyPressedAlt = false;

  bool isKeyPressedCtrl = false;

  bool isKeyPressedMeta = false;

  bool isKeyPressedShift = false;

  static const Color shadow = Color(0x55000000);

  late bool showingOverlay;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.requestFocus();
    showingOverlay = widget.showMap;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(final KeyboardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  ///Returns the keyboard widget on desktop platforms. It does not
  ///provide shortcuts on IOS or Android
  @override
  Widget build(final BuildContext context) {
    return Focus(
      canRequestFocus: true,
      descendantsAreFocusable: true,
      skipTraversal: false,
      focusNode: _focusNode,
      autofocus: false,
      //widget.hasFocus,
      onKeyEvent: (final FocusNode node, final KeyEvent event) {
        if (event.logicalKey == LogicalKeyboardKey.altLeft || event.logicalKey == LogicalKeyboardKey.altLeft) {
          isKeyPressedAlt = event is KeyDownEvent;
        }

        if (event.logicalKey == LogicalKeyboardKey.controlLeft || event.logicalKey == LogicalKeyboardKey.controlRight) {
          isKeyPressedCtrl = event is KeyDownEvent;
        }

        if (event.logicalKey == LogicalKeyboardKey.metaLeft || event.logicalKey == LogicalKeyboardKey.metaRight) {
          isKeyPressedMeta = event is KeyDownEvent;
        }
        if (event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight) {
          isKeyPressedShift = event is KeyDownEvent;
        }

        if (event.runtimeType == KeyDownEvent && node.hasPrimaryFocus) {
          final LogicalKeyboardKey key = event.logicalKey;

          if (key == widget.showDismissKey) {
            toggleOverlay();
            return KeyEventResult.handled;
          } else if (key == LogicalKeyboardKey.escape) {
            if (showingOverlay) {
              _hideOverlay();
            }
            return KeyEventResult.handled;
          } else {
            final KeyAction? rep = _findMatch(event);
            if (rep == null) {
              return KeyEventResult.ignored;
            } else {
              rep.callback();
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: FocusTraversalGroup(child: widget.child),
    );
  }

  void toggleOverlay() {
    setState(() {
      if (!showingOverlay) {
        showingOverlay = true;
        _overlayEntry = widget.groupByCategory ? _buildCategoryOverlay() : _buildOverlay();
        Overlay.of(context).insert(_overlayEntry);
      } else {
        if (showingOverlay) {
          _hideOverlay();
        }
      }
    });
  }

  OverlayEntry _buildCategoryOverlay() {
    final ThemeData theme = Theme.of(context);
    final TextStyle? bodyText = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final TextStyle categoryTextStyle = bodyText ?? const TextStyle().copyWith(fontWeight: FontWeight.bold);

    final Map<String, List<KeyAction>> map = _getBindingsMap();
    final int length = map.length + widget.bindings.length;

    final MediaQueryData media = MediaQuery.of(context);
    final Size size = media.size;
    final List<List<DataCell>> tableRows = <List<DataCell>>[];
    for (int k = 0; k < length; k++) {
      tableRows.add(<DataCell>[]);
    }

    final List<Widget> rows = <Widget>[];
    for (String category in map.keys) {
      final Container header = Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(width: 2.0)),
        ),
        padding: const EdgeInsets.only(top: 6),
        child: Text(category, style: categoryTextStyle),
      );
      rows.add(header);

      final List<KeyAction> actions = map[category]!;
      final Widget table = _getTableForActions(actions);
      rows.add(table);
    }
    final Widget dataTable = SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: ListView(shrinkWrap: true, children: rows),
    );

    return OverlayEntry(
      builder: (final BuildContext context) {
        return Positioned(
          child: GestureDetector(
            onTap: () {
              _hideOverlay();
            },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(horizontalMargin),
              width: size.width,
              height: size.height,
              decoration: const BoxDecoration(color: Colors.white),
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    alignment: Alignment.center,
                    child: dataTable,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  OverlayEntry _buildOverlay() {
    final ThemeData themeData = Theme.of(context);
    final TextStyle textStyle = widget.textStyle ?? themeData.textTheme.labelSmall ?? defaultTextStyle;
    final Color background = widget.backgroundColor ?? themeData.cardColor;
    final Color textColor = textStyle.color ?? defaultTextColor;

    final MediaQueryData media = MediaQuery.of(context);
    final Size size = media.size;
    final int length = widget.bindings.length;

    final int rowCount = (length / widget.columnCount).ceil();
    final List<List<DataCell>> tableRows = <List<DataCell>>[];
    for (int k = 0; k < rowCount; k++) {
      tableRows.add(<DataCell>[]);
    }
    final List<DataColumn> columns = <DataColumn>[];
    for (int k = 0; k < widget.columnCount; k++) {
      columns.add(const DataColumn(label: Text('d')));
      columns.add(const DataColumn(label: Text('m'), numeric: true));
      columns.add(const DataColumn(label: Text('k')));
    }
    final int fullRows = length ~/ widget.columnCount;
    for (int k = 0; k < fullRows; k++) {
      final List<DataCell> dataRow = tableRows[k];
      for (int t = 0; t < widget.columnCount; t++) {
        final KeyAction rep = widget.bindings[k * widget.columnCount + t];
        final String modifiers = _getModifiers(rep);

        dataRow.add(
          DataCell(
            Text(
              rep.description,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        );
        dataRow.add(
          modifiers.isNotEmpty
              ? DataCell(
                  _getBubble(
                    modifiers,
                    textColor,
                    background,
                    textStyle,
                    invert: true,
                  ),
                )
              : DataCell.empty,
        );
        dataRow.add(
          DataCell(_getBubble(rep.label, textColor, background, textStyle)),
        );
      }
    }
    if (widget.bindings.length % widget.columnCount != 0) {
      final List<DataCell> dataRow = tableRows[fullRows];
      for (int k = fullRows * widget.columnCount; k < widget.bindings.length; k++) {
        final KeyAction rep = widget.bindings[k];
        final String modifiers = _getModifiers(rep);
        dataRow.add(
          DataCell(
            Text(
              rep.description,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        );
        dataRow.add(
          modifiers.isNotEmpty
              ? DataCell(
                  _getBubble(modifiers, textColor, background, textStyle),
                )
              : DataCell.empty,
        );
        dataRow.add(
          DataCell(
            _getBubble(
              rep.label,
              textColor,
              background,
              textStyle,
              invert: true,
            ),
          ),
        );
      }
      for (int k = widget.bindings.length; k < rowCount * widget.columnCount; k++) {
        dataRow.add(DataCell.empty);
        dataRow.add(DataCell.empty);
        dataRow.add(DataCell.empty);
      }
    }
    final List<DataRow> rows = <DataRow>[];
    for (List<DataCell> cells in tableRows) {
      rows.add(DataRow(cells: cells));
    }

    final Color dividerColor = widget.showLines ? themeData.dividerColor : Colors.transparent;
    final Widget dataTable = Theme(
      data: Theme.of(context).copyWith(dividerColor: dividerColor),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columnSpacing: 2,
          dividerThickness: 1,
          columns: columns,
          rows: rows,
          dataRowMinHeight: 4 + (textStyle.fontSize ?? 12.0),
          dataRowMaxHeight: 20 + (textStyle.fontSize ?? 12.0),
          headingRowHeight: 0,
        ),
      ),
    );

    final Widget grid = Container(
      alignment: Alignment.center,
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: background, width: 12),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: shadow, blurRadius: 30, spreadRadius: 1),
        ],
      ),
      child: (widget.helpText != null)
          ? Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  child: Markdown(
                    shrinkWrap: true,
                    data: widget.helpText!,
                    styleSheet: MarkdownStyleSheet(
                      h1: const TextStyle(fontWeight: FontWeight.bold),
                      h1Align: WrapAlignment.center,
                    ),
                  ),
                ),
                const Divider(height: 0.5, thickness: 0.5),
                const SizedBox(height: 18),
                dataTable,
              ],
            )
          : dataTable,
    );

    return OverlayEntry(
      builder: (final BuildContext context) {
        return Positioned(
          child: GestureDetector(
            onTap: () {
              _hideOverlay();
            },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(horizontalMargin),
              width: size.width,
              // - padding.left - padding.right - 40,
              height: size.height,
              // - padding.top - padding.bottom - 40,
              decoration: const BoxDecoration(color: Colors.black12),
              child: Material(
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    alignment: Alignment.center,
                    child: grid,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  KeyAction? _findMatch(final KeyEvent event) {
    for (KeyAction rep in widget.bindings) {
      if (rep.matchesEvent(event, isKeyPressedMeta)) {
        return rep;
      }
    }
    return null;
  }

  Widget _getAltText(final String text, final TextStyle textStyle) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      child: Text(text, style: textStyle),
    );
  }

  Map<String, List<KeyAction>> _getBindingsMap() {
    final Map<String, List<KeyAction>> map = <String, List<KeyAction>>{};
    for (KeyAction ka in widget.bindings) {
      final String category = ka.categoryHeader;
      if (!map.containsKey(category)) {
        map[category] = <KeyAction>[];
      }
      map[category]!.add(ka);
    }
    return map;
  }

  Widget _getBubble(
    final String text,
    final Color color,
    final Color color2,
    final TextStyle textStyle, {
    final bool invert = false,
  }) {
    // bool isDark = background.computeLuminance() < .5;
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: invert ? color : color2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: textStyle.copyWith(color: invert ? color2 : color),
      ), //isDark? _whiteStyle :_blackStyle,),
    );
  }

  List<DataCell> _getDataRow(
    final KeyAction rep,
    final TextStyle textStyle,
    final TextStyle altTextStyle,
    final Color background,
    final Color textColor,
  ) {
    final List<DataCell> dataRow = <DataCell>[];
    final String modifiers = _getModifiers(rep);
    dataRow.add(
      DataCell(
        Text(
          rep.description,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        ),
      ),
    );
    dataRow.add(
      modifiers.isNotEmpty ? DataCell(_getBubble(modifiers, textColor, background, altTextStyle)) : DataCell.empty,
    );
    dataRow.add(DataCell(_getAltText(rep.label, altTextStyle)));
    return dataRow;
  }

  String _getModifiers(final KeyAction rep) {
    final StringBuffer buffer = StringBuffer();
    if (rep.isMetaPressed) {
      //Platform operating system is not available in the web platform
      if (!kIsWeb && Platform.isMacOS) {
        buffer.write('⌘');
      } else {
        buffer.write('meta ');
      }
    }
    if (rep.isShiftPressed) {
      if (kIsWeb) {
        buffer.write('shift ');
      } else {
        buffer.write('⇧');
      }
    }
    if (rep.isControlPressed) {
      if (!kIsWeb && Platform.isMacOS) {
        buffer.write('⌃');
      } else {
        buffer.write('ctrl ');
      }
    }
    if (rep.isAltPressed) {
      if (!kIsWeb && Platform.isMacOS) {
        buffer.write('⌥');
      } else {
        buffer.write('alt ');
      }
    }
    if (kIsWeb || !Platform.isMacOS) {
      return buffer.toString().trimRight();
    } else {
      return buffer.toString();
    }
  }

  Widget _getTableForActions(final List<KeyAction> actions) {
    final int colCount = widget.columnCount;
    final ThemeData theme = Theme.of(context);
    final TextStyle textStyle = widget.textStyle ?? theme.textTheme.labelSmall ?? defaultTextStyle;
    final TextStyle altTextStyle = textStyle.copyWith(
      fontWeight: FontWeight.bold,
    );
    final Color background = widget.backgroundColor ?? theme.cardColor;
    final Color textColor = textStyle.color ?? defaultTextColor;

    final List<DataColumn> columns = <DataColumn>[];
    for (int k = 0; k < colCount; k++) {
      columns.add(const DataColumn(label: Text('d')));
      columns.add(const DataColumn(label: Text('m'), numeric: true));
      columns.add(const DataColumn(label: Text('k')));
    }

    final int rowCount = (actions.length / colCount).ceil();
    final int fullRows = actions.length ~/ colCount;

    final List<List<DataCell>> tableRows = <List<DataCell>>[];
    for (int k = 0; k < rowCount; k++) {
      tableRows.add(<DataCell>[]);
    }

    for (int k = 0; k < fullRows; k++) {
      final List<DataCell> dataRow = tableRows[k];
      for (int t = 0; t < colCount; t++) {
        final KeyAction rep = actions[k * colCount + t];
        dataRow.addAll(
          _getDataRow(rep, textStyle, altTextStyle, background, textColor),
        );
      }
    }
    if (actions.length % colCount != 0) {
      for (int k = fullRows * colCount; k < actions.length; k++) {
        final KeyAction rep = actions[k];
        tableRows[k].addAll(
          _getDataRow(rep, textStyle, altTextStyle, background, textColor),
        );
      }
      for (int k = actions.length; k < rowCount * colCount; k++) {
        tableRows[k].add(DataCell.empty);
        tableRows[k].add(DataCell.empty);
        tableRows[k].add(DataCell.empty);
      }
    }
    final List<DataRow> rows = <DataRow>[];
    for (List<DataCell> cells in tableRows) {
      rows.add(DataRow(cells: cells));
    }

    final ThemeData data = Theme.of(context);
    final Color dividerColor = widget.showLines ? data.dividerColor : Colors.transparent;
    return Theme(
      data: data.copyWith(dividerColor: dividerColor),
      child: DataTable(
        columns: columns,
        rows: rows,
        columnSpacing: 2,
        dividerThickness: 1,
        dataRowMinHeight: 4 + (textStyle.fontSize ?? 12.0),
        dataRowMaxHeight: 18 + (textStyle.fontSize ?? 12.0),
        headingRowHeight: 0,
      ),
    );
  }

  void _hideOverlay() {
    setState(() {
      showingOverlay = false;
      _overlayEntry.remove();
      if (widget.callbackOnHide != null) {
        widget.callbackOnHide!();
      }
    });
  }
}

///A combination of a [LogicalKeyboardKey] (e.g., control-shift-A), a description
///of what action that keystroke should trigger (e.g., "select all text"),
///and a callback method to be invoked when that keystroke is pressed. Optionally
///includes a category header for the shortcut.
@immutable
class KeyAction {
  ///Creates a KeystrokeRep with the given LogicalKeyboardKey [keyStroke],
  ///[description] and [callback] method. Includes optional bool values (defaulting
  ///to false) for key modifiers for meta [isMetaPressed], shift [isShiftPressed],
  ///alt [isAltPressed]
  KeyAction(
    final LogicalKeyboardKey keyStroke,
    this.description,
    this.callback, {
    this.categoryHeader = '',
    final bool isControlPressed = false,
    final bool isMetaPressed = false,
    final bool isShiftPressed = false,
    final bool isAltPressed = false,
  }) : keyActivator = SingleActivator(
         keyStroke,
         control: isControlPressed,
         shift: isShiftPressed,
         alt: isAltPressed,
         meta: isMetaPressed,
       );

  ///Creates a key action from the first letter of any string [string] with,
  ///[description] and [callback] method. Includes optional bool values (defaulting
  ///to false) for key modifiers for meta [isMetaPressed], shift [isShiftPressed],
  ///alt [isAltPressed]
  KeyAction.fromString(
    final String string,
    this.description,
    this.callback, {
    this.categoryHeader = '',
    final bool isControlPressed = false,
    final bool isMetaPressed = false,
    final bool isShiftPressed = false,
    final bool isAltPressed = false,
  }) : keyActivator = SingleActivator(
         LogicalKeyboardKey(string.toLowerCase().codeUnitAt(0)),
         control: isControlPressed,
         shift: isShiftPressed,
         alt: isAltPressed,
         meta: isMetaPressed,
       );

  final VoidCallback callback;
  final String categoryHeader;
  final String description;
  final SingleActivator keyActivator;

  bool get isAltPressed => keyActivator.alt;

  bool get isControlPressed => keyActivator.control;

  bool get isMetaPressed => keyActivator.meta;

  bool get isShiftPressed => keyActivator.shift;

  String get label {
    final LogicalKeyboardKey key = keyActivator.trigger;
    String label = keyActivator.trigger.keyLabel;
    if (key == LogicalKeyboardKey.arrowRight) {
      if (kIsWeb) {
        label = 'arrow right';
      } else {
        label = '→';
      }
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      if (kIsWeb) {
        label = 'arrow left';
      } else {
        label = '←';
      }
    } else if (key == LogicalKeyboardKey.arrowUp) {
      if (kIsWeb) {
        label = 'arrow up';
      } else {
        label = '↑';
      }
    } else if (key == LogicalKeyboardKey.arrowDown) {
      if (kIsWeb) {
        label = 'arrow down';
      } else {
        label = '↓';
      }
    } else if (key == LogicalKeyboardKey.delete) {
      if (kIsWeb) {
        label = 'delete';
      } else {
        label = '\u232B';
      }
    }
    // else if (key == LogicalKeyboardKey.enter) {
    //   if (kIsWeb) {
    //     label = 'enter';
    //   }
    //   else {
    //     label = '\u2B90';
    //   }
    // }
    return label;
  }

  bool matchesEvent(final KeyEvent event, bool isKeyPressedMeta) {
    if (event.logicalKey == keyActivator.trigger) {
      if (isMetaPressed && isKeyPressedMeta) {
        return true;
      }
    }
    return false;
  }
}
