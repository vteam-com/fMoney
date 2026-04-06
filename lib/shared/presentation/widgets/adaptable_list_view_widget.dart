import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/widgets/components/app_scaffold_widget.dart';
import 'package:money/widgets/list/adaptive_columns_or_rows_list_widget.dart';
import 'package:money/widgets/pure/scale_down_widget.dart';
import 'package:money/widgets/state/preferences_controller.dart';
import 'package:money/widgets/state/theme_controller.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/field_filters_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';
import 'package:multi_split_view/multi_split_view.dart';

export 'package:flutter/material.dart';

const double _zeroDouble = 0.0;
const double _sidePanelExpandedMinExtra = 100.0;

/// A stateful widget for adaptive view with list.
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

  final List<DataObject> list;

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
  bool _isPersistingSidePanelHeight = false;
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
      builder: (final BuildContext context, final BoxConstraints _) {
        final bool displayAsColumns = context.isWidthSmall == false;

        return Focus(
          focusNode: _keyboardFocusNode,
          // On web, route/view focus can be requested before the list is laid
          // out, which trips focus traversal assertions.
          autofocus: !kIsWeb,
          onKeyEvent: _handleKeyboardShortcuts,
          child: ValueListenableBuilder<List<int>>(
            valueListenable: widget.selectedItemsByUniqueId,
            builder:
                (
                  final BuildContext _,
                  final List<int> selectedItems,
                  final _,
                ) {
                  keepUnused(selectedItems);
                  return MultiSplitView(
                    controller: _splitController,
                    axis: Axis.vertical,
                    dividerBuilder: _buildSplitDivider,
                    builder: (BuildContext _, Area area) {
                      return area.index == 0 ? topSection(displayAsColumns) : widget.bottom;
                    },
                  );
                },
          ),
        );
      },
    );
  }

  /// Builds the top section widget containing title and content.
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

  /// Builds the draggable divider widget between the main list and side panel.
  Widget _buildSplitDivider(
    Axis axis,
    int index,
    bool resizable,
    bool dragging,
    bool highlighted,
    MultiSplitViewThemeData themeData,
  ) {
    keepUnused(axis, index, resizable, dragging);
    keepUnused(themeData);
    return ColoredBox(
      key: const Key('SidePanelSplitter'),
      color: highlighted ? ThemeController.to.primaryColor : Colors.transparent,
    );
  }

  /// Configures the split controller areas based on persisted side panel state.
  void _configureSplitPanelAreas() {
    final double minSize = PreferenceController.to.isSidePanelExpanded
        ? Constants.sidePanelHeightWhenCollapsed + _sidePanelExpandedMinExtra
        : Constants.sidePanelHeightWhenCollapsed + _zeroDouble;
    final double targetSize = PreferenceController.to.isSidePanelExpanded
        ? PreferenceController.to.sidePanelHeight.toDouble()
        : Constants.sidePanelHeightWhenCollapsed.toDouble();

    if (_splitController.areas[1].min != minSize) {
      _splitController.areas[1].min = minSize;
    }

    if (_splitController.areas[1].size != targetSize) {
      _splitController.areas[1].size = targetSize;
    }
  }

  /// Handles keyboard shortcuts that toggle the side panel.
  KeyEventResult _handleKeyboardShortcuts(FocusNode _, KeyEvent event) {
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

  /// Persists side panel size changes after the current frame.
  void _persistSidePanelHeightIfNeeded() {
    if (!mounted || _isPersistingSidePanelHeight || !PreferenceController.to.isSidePanelExpanded) {
      return;
    }

    final double? currentSize = _splitController.areas[1].size;
    if (currentSize == null) {
      return;
    }

    final int newHeight = currentSize.toInt();
    if (PreferenceController.to.sidePanelHeight == newHeight) {
      return;
    }

    _isPersistingSidePanelHeight = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isPersistingSidePanelHeight = false;
      if (!mounted || !PreferenceController.to.isSidePanelExpanded) {
        return;
      }

      final double? scheduledSize = _splitController.areas[1].size;
      if (scheduledSize == null) {
        return;
      }

      final int scheduledHeight = scheduledSize.toInt();
      if (PreferenceController.to.sidePanelHeight != scheduledHeight) {
        PreferenceController.to.sidePanelHeight = scheduledHeight;
      }
    });
  }

  /// Persists side panel size changes when rebuilding.
  void _rebuild() {
    _persistSidePanelHeightIfNeeded();
  }

  void _toggleSidePanel() {
    setState(() {
      PreferenceController.to.isSidePanelExpanded = !PreferenceController.to.isSidePanelExpanded;
    });
    HapticFeedback.lightImpact();
  }
}
