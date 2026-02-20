import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/pure/gaps.dart';

// Exports
export 'package:flutter/material.dart';
export 'package:money/widgets/pure/scale_down.dart';

const double _columnFilterPanelWidth = 300;

/// A stateful widget for column filter panel.
class ColumnFilterPanel extends StatefulWidget {
  const ColumnFilterPanel({
    required this.listOfUniqueInstances,
    super.key,
    this.textAlign = TextAlign.left,
  });

  final List<ValueSelection> listOfUniqueInstances;
  final TextAlign textAlign;

  @override
  State<ColumnFilterPanel> createState() => _ColumnFilterPanelState();
}

class _ColumnFilterPanelState extends State<ColumnFilterPanel> {
  String filterText = '';
  late List<ValueSelection> list;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    list = widget.listOfUniqueInstances
        .where(
          (ValueSelection element) =>
              filterText.isEmpty || element.name.toLowerCase().contains(filterText.toLowerCase()),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Filter input box
        TextField(
          key: const Key('key_picker_input_filter'),
          onChanged: (String value) {
            setState(() {
              filterText = value;
            });
          },
          decoration: const InputDecoration(
            labelText: 'filter',
            border: OutlineInputBorder(),
          ),
        ),

        gapLarge(),

        // Clear All / Select  All
        TextButton(
          key: const Key('key_select_unselect_all'),
          onPressed: () {
            setState(() {
              final bool setAs = !areAllItemSelected();
              for (final ValueSelection item in list) {
                item.isSelected = setAs;
              }
            });
          },
          child: Text(
            '${areAllItemSelected() ? 'Unselect all' : 'Select all'} ${getItemCounts()}',
          ),
        ),
        Expanded(
          child: SizedBox(
            width: _columnFilterPanelWidth,
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (final BuildContext _, final int index) {
                return CheckboxListTile(
                  title: Text(list[index].name, textAlign: widget.textAlign),
                  value: list[index].isSelected,
                  onChanged: (final bool? isChecked) {
                    setState(() {
                      list[index].isSelected = isChecked == true;
                    });
                  },
                );
              },
            ),
          ),
        ),
        const Divider(),
        Center(child: Text('${getIntAsText(getSelectedCount())} selected')),
      ],
    );
  }

  /// true if all items are selected
  bool areAllItemSelected() {
    return list.firstWhereOrNull(
          (ValueSelection element) => element.isSelected == false,
        ) ==
        null;
  }

  String getItemCounts() {
    if (list.length == widget.listOfUniqueInstances.length) {
      return getIntAsText(list.length);
    } else {
      return '${getIntAsText(list.length)}/${getIntAsText(widget.listOfUniqueInstances.length)}';
    }
  }

  int getSelectedCount() {
    return widget.listOfUniqueInstances.where((ValueSelection item) => item.isSelected).length;
  }
}

/// Represents value selection.
class ValueSelection {
  ValueSelection({required this.name, required this.isSelected});

  bool isSelected;
  String name;
}
