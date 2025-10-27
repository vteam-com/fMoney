// Imports
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:money/core/helpers/list_helper.dart';
import 'package:money/core/helpers/ranges.dart';
import 'package:money/data/models/money_objects/money_object.dart';
import 'package:money/views/home/sub_views/adaptive_view/adaptive_list/list_item.dart';

// Exports
export 'package:money/data/models/fields/fields.dart';
export 'package:money/data/models/money_objects/money_object.dart';

class MyListView<T> extends StatefulWidget {
  const MyListView({
    required this.fields,
    required this.list,
    required this.selectedItemIds,
    required this.scrollController,
    super.key,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.displayAsColumn = true,
    this.onSelectionChanged,
    this.isMultiSelectionOn = false,
  });

  final bool displayAsColumn;

  final FieldDefinitions fields;

  final bool isMultiSelectionOn;

  final List<T> list;

  final void Function(BuildContext, int uniqueId)? onDoubleTap;

  final void Function(BuildContext, int uniqueId)? onLongPress;

  final void Function(int /* uniqueId */)? onSelectionChanged;

  final void Function(BuildContext, int uniqueId)? onTap;

  final ScrollController scrollController;

  final ValueNotifier<List<int>> selectedItemIds;

  @override
  State<MyListView<T>> createState() => MyListViewState<T>();
}

class MyListViewState<T> extends State<MyListView<T>> {
  double _rowHeight = 30;

  double padding = 0;

  @override
  Widget build(final BuildContext context) {
    final TextScaler textScaler = MediaQuery.textScalerOf(context);

    if (widget.displayAsColumn) {
      _rowHeight = 30;
      padding = 8.0;
    } else {
      _rowHeight = 85;
      padding = 0;
    }

    return ListView.builder(
      primary: false,
      scrollDirection: Axis.vertical,
      controller: widget.scrollController,
      itemCount: widget.list.length,
      itemExtent: textScaler.scale(_rowHeight),
      itemBuilder: (final BuildContext context, final int index) {
        final MoneyObject itemInstance = getMoneyObjectFromIndex(index);
        final bool isLastItemOfTheList = (index == widget.list.length - 1);
        final bool isSelected = widget.selectedItemIds.value.contains(
          itemInstance.uniqueId,
        );
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (widget.isMultiSelectionOn)
                Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedItem(itemInstance.uniqueId);
                      }
                      if (value == false) {
                        widget.selectedItemIds.value.remove(
                          itemInstance.uniqueId,
                        );
                      }
                      widget.onSelectionChanged?.call(itemInstance.uniqueId);
                      FocusScope.of(context).requestFocus();
                    });
                  },
                ),
              Expanded(
                child: MyListItem(
                  onListViewKeyEvent: onListViewKeyEvent,
                  onTap: () {
                    if (widget.selectedItemIds.value.contains(
                      itemInstance.uniqueId,
                    )) {
                      widget.selectedItemIds.value.remove(
                        itemInstance.uniqueId,
                      );
                    } else {
                      if (widget.isMultiSelectionOn == false) {
                        // single selection
                        widget.selectedItemIds.value.clear();
                      }
                      widget.selectedItemIds.value.add(itemInstance.uniqueId);
                    }
                    widget.onSelectionChanged?.call(itemInstance.uniqueId);

                    FocusScope.of(context).requestFocus();
                  },
                  onLongPress: () {
                    widget.onLongPress?.call(context, itemInstance.uniqueId);
                    FocusScope.of(context).requestFocus();
                  },
                  autoFocus: index == widget.selectedItemIds.value.firstOrNull,
                  isSelected: isSelected,
                  adornmentColor: itemInstance.getMutationColor(),
                  child: _buildListItemContent(
                    isSelected,
                    itemInstance,
                    isLastItemOfTheList,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// return -1 if not found
  int getListIndexFromUniqueId(final int uniqueId) {
    return widget.list.indexWhere(
      (final T element) => (element as MoneyObject).uniqueId == uniqueId,
    );
  }

  /// don't make it flush to the top, we do this in order to give some clue that there's other item above,
  double getListOffsetOfItemIndex(final int index) => index * _rowHeight;

  MoneyObject getMoneyObjectFromIndex(int index) {
    return widget.list[index] as MoneyObject;
  }

  int getUniqueIdFromIndex(int index) {
    return getMoneyObjectFromIndex(index).uniqueId;
  }

  /// use this if total item count is known
  NumRange indexOfItemsInView() {
    final int itemCount = widget.list.length;
    final double scrollOffset = widget.scrollController.position.pixels;
    final double viewportHeight = widget.scrollController.position.viewportDimension;
    final double scrollRange =
        widget.scrollController.position.maxScrollExtent - widget.scrollController.position.minScrollExtent;

    final int firstVisibleItemIndex = (scrollOffset / (scrollRange + viewportHeight) * itemCount).ceil();
    final int lastVisibleItemIndex = firstVisibleItemIndex + numberOfItemOnViewPort() - 1;

    return NumRange(min: firstVisibleItemIndex, max: lastVisibleItemIndex);
  }

  bool isIndexInView(final int index) {
    if (index != -1) {
      final NumRange viewingIndexRange = indexOfItemsInView();
      if (index.isBetween(viewingIndexRange.min, viewingIndexRange.max)) {
        return true;
      }
    }
    return false;
  }

  int moveCurrentSelection(final int incrementBy) {
    int itemIdToSelect = -1;
    final int firstSelectedIndex = getListIndexFromUniqueId(
      widget.selectedItemIds.value.first,
    );
    if (firstSelectedIndex != -1) {
      final int newIndexToSelect = firstSelectedIndex + incrementBy; // go up
      if (isIndexInRange(widget.list, newIndexToSelect)) {
        final T itemFoundAtNewIndexPosition = widget.list[newIndexToSelect];
        itemIdToSelect = (itemFoundAtNewIndexPosition as MoneyObject).uniqueId;
      }
    } else {
      itemIdToSelect = (widget.list.first as MoneyObject).uniqueId;
    }

    scrollToId(itemIdToSelect);
    return itemIdToSelect;
  }

  int numberOfItemOnViewPort() {
    final double viewportHeight = widget.scrollController.position.viewportDimension;
    final int numberOfItemDisplayed = (viewportHeight / _rowHeight).floor();
    return numberOfItemDisplayed;
  }

  KeyEventResult onListViewKeyEvent(
    final FocusNode node,
    final KeyEvent event,
  ) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowUp:
          if (widget.selectedItemIds.value.isNotEmpty) {
            final int itemIdToSelect = moveCurrentSelection(-1);
            if (itemIdToSelect != -1) {
              selectedItem(itemIdToSelect);
            }
          }
          return KeyEventResult.handled;

        case LogicalKeyboardKey.arrowDown:
          if (widget.selectedItemIds.value.isNotEmpty) {
            final int itemIdToSelect = moveCurrentSelection(1);
            if (itemIdToSelect != -1) {
              selectedItem(itemIdToSelect);
            }
          }
          return KeyEventResult.handled;

        case LogicalKeyboardKey.home:
          final int idToSelect = (widget.list.first as MoneyObject).uniqueId;
          selectedItem(idToSelect);
          widget.scrollController.jumpTo(getListOffsetOfItemIndex(0));
          return KeyEventResult.handled;

        case LogicalKeyboardKey.end:
          final int idToSelect = (widget.list.last as MoneyObject).uniqueId;
          selectedItem(idToSelect);
          widget.scrollController.jumpTo(
            getListOffsetOfItemIndex(widget.list.length - 1),
          );
          return KeyEventResult.handled;

        case LogicalKeyboardKey.pageUp:
        case LogicalKeyboardKey.pageDown:
          // TODO
          return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void scrollFirstItemIntoView() {
    if (widget.selectedItemIds.value.isNotEmpty) {
      scrollToId(widget.selectedItemIds.value.first);
    }
  }

  /// if the uniqueID is valid,
  /// if the index of this ID is valid
  /// if the item is not in view
  /// then and only then we scroll the item into view
  void scrollToId(final int uniqueId) {
    if (-1 != uniqueId) {
      final int index = getListIndexFromUniqueId(uniqueId);
      scrollToIndex(index);
    }
  }

  void scrollToIndex(final int index) {
    if (!widget.scrollController.hasClients) {
      // not yet attached to a list
      return;
    }

    if (isIndexInRange(widget.list, index)) {
      final NumRange viewingIndexRange = indexOfItemsInView();
      if (isBetweenOrEqual(
        index,
        viewingIndexRange.min,
        viewingIndexRange.max,
      )) {
        // item is already on the screen
        // print('$index is range $viewingIndexRange');
      } else {
        // item is outside the view port list

        //print('$index is Out of range $viewingIndexRange -----------');

        // make the default scroll near the top
        late double desiredNewPosition;
        if (index == viewingIndexRange.min - 1) {
          // scroll up by one
          desiredNewPosition = widget.scrollController.offset - _rowHeight;
        } else {
          if (index == viewingIndexRange.max + 1) {
            desiredNewPosition = widget.scrollController.offset + _rowHeight;
          } else {
            desiredNewPosition = _rowHeight * index;
          }
        }
        final int numberOfItems = (desiredNewPosition / _rowHeight).floor();
        desiredNewPosition = numberOfItems * _rowHeight;

        //print('current offset ${_scrollController.offset}, requesting $desiredNewPosition for index $index');
        widget.scrollController.jumpTo(desiredNewPosition);
      }
    }
  }

  void selectedItem(final int uniqueId) {
    if (widget.isMultiSelectionOn == false) {
      // single selection so remove any other selection before selecting an item
      widget.selectedItemIds.value.clear();
    }

    // only add if not already there
    if (!widget.selectedItemIds.value.contains(uniqueId)) {
      widget.selectedItemIds.value.add(uniqueId);
      widget.onSelectionChanged?.call(uniqueId);
    }
  }

  void selectedItemOffset(final int delta) {
    int newPosition = 0;
    if (widget.selectedItemIds.value.isNotEmpty) {
      newPosition = widget.selectedItemIds.value[0] + delta;
    }

    selectedItem(newPosition);
  }

  Widget _buildListItemContent(
    final bool isSelected,
    final MoneyObject itemInstance,
    final bool isLastItemOfTheList,
  ) {
    return widget.displayAsColumn
        ? itemInstance.buildFieldsAsWidgetForLargeScreen(widget.fields)
        : Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? getColorTheme(context).primaryContainer : getColorTheme(context).surface,
              border: Border(
                bottom: BorderSide(
                  width: 1,
                  color: isLastItemOfTheList ? Colors.transparent : Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: itemInstance.buildFieldsAsWidgetForSmallScreen(),
          );
  }
}
