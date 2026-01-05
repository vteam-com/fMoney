import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/list_controller.dart';
import 'package:money/widgets/adaptive_list/list_item_footer.dart';
import 'package:money/widgets/adaptive_list/list_item_header.dart';
import 'package:money/widgets/adaptive_list/list_view.dart';
import 'package:money/widgets/field.dart';
import 'package:money/widgets/field_filters.dart';
import 'package:money/widgets/money_object.dart';
import 'package:money/widgets/scale_down.dart';

class AdaptiveListColumnsOrRows extends StatelessWidget {
  const AdaptiveListColumnsOrRows({
    super.key,
    required this.list,
    required this.fieldDefinitions,
    required this.filters,
    required this.selectedItemsByUniqueId,
    required this.displayAsColumns,
    required this.listController,
    this.sortByFieldIndex = 0,
    this.sortAscending = true,
    this.isMultiSelectionOn = false,
    this.onSelectionChanged,
    this.onContextMenu,
    this.onColumnHeaderTap,
    this.onColumnHeaderLongPress,
    this.onItemTap,
    this.onItemLongPress,
    this.getColumnFooterWidget,
    this.backgroundColorForHeaderFooter,
  });

  final Color? backgroundColorForHeaderFooter;

  final bool displayAsColumns;

  final FieldDefinitions fieldDefinitions;

  final FieldFilters filters;

  final Widget? Function(Field<dynamic> field)? getColumnFooterWidget;

  final bool isMultiSelectionOn;

  final List<MoneyObject> list;

  final ListController listController;

  final void Function(Field<dynamic> field)? onColumnHeaderLongPress;

  final void Function(int columnHeaderIndex)? onColumnHeaderTap;

  final void Function()? onContextMenu;

  final void Function(BuildContext context, int itemId)? onItemLongPress;

  final void Function(BuildContext context, int itemId)? onItemTap;

  final void Function(int uniqueId)? onSelectionChanged;

  final ValueNotifier<List<int>> selectedItemsByUniqueId;

  final bool sortAscending;

  final int sortByFieldIndex;

  @override
  Widget build(BuildContext context) {
    final Column theContent = Column(
      children: <Widget>[
        // Header
        if (displayAsColumns)
          MyListItemHeader<MoneyObject>(
            backgroundColor: backgroundColorForHeaderFooter ?? getColorTheme(context).surfaceContainerLow,
            columns: fieldDefinitions,
            filterOn: filters,
            sortByColumn: sortByFieldIndex,
            sortAscending: sortAscending,
            itemsAreAllSelected: list.length == selectedItemsByUniqueId.value.length,
            onSelectAll: isMultiSelectionOn
                ? (bool selectAllRequested) {
                    selectedItemsByUniqueId.value.clear();
                    if (selectAllRequested) {
                      for (final MoneyObject item in list) {
                        selectedItemsByUniqueId.value.add(item.uniqueId);
                      }
                    }
                    onSelectionChanged?.call(-1);
                  }
                : null,
            onTap: (int index) => onColumnHeaderTap?.call(index),
            onLongPress: (Field<dynamic> field) => onColumnHeaderLongPress?.call(field),
          ),

        // The actual List
        Expanded(
          flex: 1,
          child: MyListView<MoneyObject>(
            fields: fieldDefinitions,
            list: list,
            selectedItemIds: selectedItemsByUniqueId,
            isMultiSelectionOn: isMultiSelectionOn,
            onSelectionChanged: onSelectionChanged,
            displayAsColumn: displayAsColumns,
            onTap: onItemTap,
            onLongPress: onItemLongPress,
            scrollController: listController.scrollController,
          ),
        ),

        // Footer
        if (displayAsColumns && getColumnFooterWidget != null)
          MyListItemFooter<MoneyObject>(
            backgroundColor: backgroundColorForHeaderFooter ?? getColorTheme(context).surfaceContainerLow,
            columns: fieldDefinitions,
            multiSelectionOn: isMultiSelectionOn,
            getColumnFooterWidget: getColumnFooterWidget!,
            onTap: (int index) => () {},
            onLongPress: (Field<dynamic> field) => () {},
          ),
      ],
    );

    if (displayAsColumns && !context.isWidthLarge) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(width: 1500, child: theContent),
      );
    } else {
      return theContent;
    }
  }
}
