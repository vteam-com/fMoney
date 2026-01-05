import 'dart:io';

import 'package:flutter/services.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/views/app_scaffold.dart';
import 'package:money/views/models/adaptive_list/adaptive_columns_or_rows_list.dart';
import 'package:money/widgets/field.dart';
import 'package:money/widgets/field_filters.dart';
import 'package:money/widgets/misc_widgets.dart';
import 'package:money/widgets/money_object.dart';
import 'package:money/widgets/money_objects.dart';
import 'package:money/widgets/preferences_controller.dart';
import 'package:money/widgets/theme_controller.dart';
import 'package:multi_split_view/multi_split_view.dart';

export 'package:flutter/material.dart';

class AdaptiveViewWithList extends StatefulWidget {
  const AdaptiveViewWithList({
    super.key,
    required this.top,
    required this.list,
    required this.bottom,
    required this.fieldDefinitions,
    required this.filters,
    required this.selectedItemsByUniqueId,
    required this.onSelectionChanged,
    required this.isMultiSelectionOn,
    required this.listController,
    this.flexBottom = 1,
    this.sortByFieldIndex = 0,
    this.sortAscending = true,
    this.applySorting = true,
    this.onItemTap,
    this.onColumnHeaderTap,
    this.onColumnHeaderLongPress,
    this.getColumnFooterWidget,
  });

  final bool applySorting;

  final Widget bottom;

  final FieldDefinitions fieldDefinitions;

  final FieldFilters filters;

  final int flexBottom;

  final Widget? Function(Field<dynamic> field)? getColumnFooterWidget;

  final bool isMultiSelectionOn;

  final List<MoneyObject> list;

  final ListController listController;

  final void Function(Field<dynamic> field)? onColumnHeaderLongPress;

  final void Function(int columnHeaderIndex)? onColumnHeaderTap;

  final void Function(BuildContext, int)? onItemTap;

  final void Function(int) onSelectionChanged;

  final ValueNotifier<List<int>> selectedItemsByUniqueId;

  final bool sortAscending;

  final int sortByFieldIndex;

  final Widget top;

  @override
  State<AdaptiveViewWithList> createState() => _AdaptiveViewWithListState();
}

class _AdaptiveViewWithListState extends State<AdaptiveViewWithList> {
  final FocusNode _keyboardFocusNode = FocusNode();

  final MultiSplitViewController _splitController = MultiSplitViewController();

  @override
  void initState() {
    super.initState();

    // final double hightOfTopPanel = widget.preferences.sidePanelDistance;
    _splitController.areas = <Area>[
      Area(flex: 1),
      Area(
        size: PreferenceController.to.sidePanelHeight.toDouble(),
        min: Constants.sidePanelHeightWhenCollapsed.toDouble(),
      ),
    ];
    // start listening to user change
    _splitController.addListener(_rebuild);
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _splitController.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.applySorting) {
      MoneyObjects.sortList(
        widget.list,
        widget.fieldDefinitions,
        widget.sortByFieldIndex,
        widget.sortAscending,
      );
    }

    // Extract panel configuration to a separate method for clarity
    _configureSplitPanelAreas();

    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        final bool displayAsColumns = context.isWidthSmall == false;

        return Focus(
          focusNode: _keyboardFocusNode,
          autofocus: true,
          onKeyEvent: _handleKeyboardShortcuts,
          child: ValueListenableBuilder<List<int>>(
            valueListenable: widget.selectedItemsByUniqueId,
            builder:
                (
                  final BuildContext context,
                  final List<int> selectedItems,
                  final _,
                ) {
                  return MultiSplitView(
                    controller: _splitController,
                    axis: Axis.vertical,
                    dividerBuilder: _buildSplitDivider,
                    builder: (BuildContext context, Area area) {
                      return area.index == 0 ? topSection(displayAsColumns) : widget.bottom;
                    },
                  );
                },
          ),
        );
      },
    );
  }

  Widget topSection(final bool displayAsColumns) {
    return Column(
      children: <Widget>[
        // Top - Title area
        widget.top,

        // Middle
        Expanded(
          child: AdaptiveListColumnsOrRows(
            // List of Money Object instances
            list: widget.list,
            fieldDefinitions: widget.fieldDefinitions,
            filters: widget.filters,
            sortByFieldIndex: widget.sortByFieldIndex,
            sortAscending: widget.sortAscending,
            listController: widget.listController,

            // Display as Cards or Columns
            // On small device you can display rows a Cards instead of Columns
            displayAsColumns: displayAsColumns,
            onColumnHeaderTap: widget.onColumnHeaderTap,
            onColumnHeaderLongPress: widget.onColumnHeaderLongPress,
            getColumnFooterWidget: widget.getColumnFooterWidget,

            // Selection
            onItemTap: widget.onItemTap,
            selectedItemsByUniqueId: widget.selectedItemsByUniqueId,
            isMultiSelectionOn: widget.isMultiSelectionOn,
            onSelectionChanged: widget.onSelectionChanged,
            onContextMenu: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildSplitDivider(
    Axis axis,
    int index,
    bool resizable,
    bool dragging,
    bool highlighted,
    MultiSplitViewThemeData themeData,
  ) {
    return ColoredBox(
      key: const Key('SidePanelSplitter'),
      color: highlighted ? ThemeController.to.primaryColor : Colors.transparent,
    );
  }

  void _configureSplitPanelAreas() {
    if (PreferenceController.to.isSidePanelExpanded) {
      _splitController.areas[1].min = Constants.sidePanelHeightWhenCollapsed + 100.0;
      _splitController.areas[1].size = PreferenceController.to.sidePanelHeight.toDouble();
    } else {
      _splitController.areas[1].min = Constants.sidePanelHeightWhenCollapsed + 0.0;
      _splitController.areas[1].size = Constants.sidePanelHeightWhenCollapsed.toDouble();
    }
  }

  KeyEventResult _handleKeyboardShortcuts(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      // F9 shortcut
      if (event.logicalKey == LogicalKeyboardKey.f9) {
        _toggleSidePanel();
        return KeyEventResult.handled;
      }

      // Command+J for macOS or Ctrl+J for Windows/Linux
      if (event.logicalKey == LogicalKeyboardKey.keyJ &&
          (Platform.isMacOS ? HardwareKeyboard.instance.isMetaPressed : HardwareKeyboard.instance.isControlPressed)) {
        _toggleSidePanel();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  void _rebuild() async {
    if (PreferenceController.to.isSidePanelExpanded) {
      // save the height of the side panel
      PreferenceController.to.sidePanelHeight = _splitController.areas[1].size!.toInt();
    }
  }

  void _toggleSidePanel() {
    setState(() {
      PreferenceController.to.isSidePanelExpanded = !PreferenceController.to.isSidePanelExpanded;
    });
    HapticFeedback.lightImpact();
  }
}
