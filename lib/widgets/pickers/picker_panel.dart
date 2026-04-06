import 'dart:math';

import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/widgets/dialogs/dialog_widget.dart';
import 'package:money/widgets/pickers/letter_picker_widget.dart';
import 'package:money/widgets/pickers/token_text_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:money/widgets/pure/my_text_input_widget.dart';

const double _defaultPickerWidth = 200;
const double _defaultItemHeight = 40;
const double _panelHeight = 500;
const double _itemDividerAlpha = 0.2;
const double _itemDividerWidth = 1;
const int _scrollOffsetItems = 2;

/// Shows a popup selection dialog with optional letter picker.
void showPopupSelection({
  required BuildContext context,
  required String title,
  required List<String> items,
  required String selectedItem,
  required void Function(String _ /* text */) onSelected,
  bool showLetterPicker = true,
  TokenTextStyle tokenTextStyle = const TokenTextStyle(
    separatorPaddingLeft: SizeForPadding.nano,
    separatorPaddingRight: SizeForPadding.nano,
  ),
  bool rightAligned = false,
  double? width = _defaultPickerWidth,
}) {
  adaptiveScreenSizeDialog(
    context: context,
    title: title,
    child: PickerPanel(
      width: width,
      showLetterPicker: showLetterPicker,
      tokenTextStyle: tokenTextStyle,
      rightAligned: rightAligned,
      options: items,
      selectedItem: selectedItem,
      onSelected: onSelected,
    ),
    actionButtons: <Widget>[],
  );
}

/// A stateful widget for picker panel.
class PickerPanel extends StatefulWidget {
  const PickerPanel({
    required this.options,
    required this.selectedItem,
    required this.onSelected,
    super.key,
    this.width = _defaultPickerWidth,
    this.itemHeight = _defaultItemHeight,
    this.showLetterPicker = true,
    this.tokenTextStyle = const TokenTextStyle(),
    this.rightAligned = false,
  });

  final double itemHeight;
  final void Function(String selectedValue) onSelected;
  final List<String> options;
  final bool rightAligned;
  final String selectedItem;
  final bool showLetterPicker;
  final TokenTextStyle tokenTextStyle;
  final double? width;

  @override
  PickerPanelState createState() => PickerPanelState();
}

/// State for picker panel.
class PickerPanelState extends State<PickerPanel> {
  String _filterByTextAnywhere = '';

  String _filterStartWith = '';

  final ScrollController _scrollController = ScrollController();

  List<String> filteredList = <String>[];

  int indexToScrollTo = -1;

  List<String> uniqueLetters = <String>[];

  @override
  void initState() {
    super.initState();
    _initializeFilters();
    _populateUniqueLetters();
    _scheduleScrollToSelectedItem();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: _panelHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildFilterTextField(),
          gapLarge(),
          Expanded(child: _buildPickerContent(context)),
        ],
      ),
    );
  }

  /// Applies text and letter filters to produce [filteredList].
  void _applyFilters() {
    setState(() {
      filteredList = widget.options.where((String option) {
        final bool matchesStart = _filterStartWith.isEmpty || option.toUpperCase().startsWith(_filterStartWith);
        final bool matchesAnywhere =
            _filterByTextAnywhere.isEmpty ||
            option.toLowerCase().contains(
              _filterByTextAnywhere.toLowerCase(),
            );
        return matchesStart && matchesAnywhere;
      }).toList();
    });
  }

  /// Builds the filter text input used to narrow down available options.
  Widget _buildFilterTextField() {
    return MyTextInput(
      key: MyKeys.keyHeaderFilterTextInput,
      hintText: AppL10n.tr(AppTranslationKeys.filter),
      onChanged: (String value) {
        setState(() {
          _filterByTextAnywhere = value;
          _applyFilters();
        });
      },
    );
  }

  /// Builds the list view of currently filtered items.
  Widget _buildFilteredList(BuildContext _) {
    return ListView.builder(
      itemCount: filteredList.length,
      controller: _scrollController,
      itemExtent: widget.itemHeight,
      itemBuilder: (BuildContext context, int index) {
        final String label = filteredList[index];
        final bool isSelected = label == widget.selectedItem;
        return _buildPickerItem(context, label, isSelected, index);
      },
    );
  }

  /// Builds the optional letter picker to quickly filter by starting letter.
  Widget _buildLetterPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SizeForPadding.medium),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          child: PickerLetters(
            options: uniqueLetters,
            selected: _filterStartWith,
            onSelected: (String selected) {
              setState(() {
                _filterStartWith = selected;
                _applyFilters();
                _scrollController.jumpTo(0);
              });
            },
          ),
        ),
      ),
    );
  }

  /// Builds the main picker content including the filtered list and optional letter picker.
  Widget _buildPickerContent(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: _buildFilteredList(context)),
        if (widget.showLetterPicker) _buildLetterPicker(),
      ],
    );
  }

  /// Builds a single selectable picker item row.
  Widget _buildPickerItem(
    BuildContext context,
    String label,
    bool isSelected,
    int index,
  ) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        widget.onSelected(label);
      },
      child: Container(
        height: widget.itemHeight,
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: isSelected ? getColorTheme(context).primaryContainer : Colors.transparent,
          border: index == filteredList.length - 1
              ? null
              : Border(
                  bottom: BorderSide(
                    color: getColorTheme(
                      context,
                    ).onSurfaceVariant.withValues(alpha: _itemDividerAlpha),
                    width: _itemDividerWidth,
                  ),
                ),
        ),
        child: SingleChildScrollView(
          reverse: widget.rightAligned,
          scrollDirection: Axis.horizontal,
          child: TokenText(label, style: widget.tokenTextStyle),
        ),
      ),
    );
  }

  /// Initializes the filtered list from the full set of options.
  void _initializeFilters() {
    setState(() {
      filteredList = widget.options;
    });
  }

  /// Populates the unique first-letter list used by the letter picker.
  void _populateUniqueLetters() {
    for (final String option in widget.options) {
      if (option.isNotEmpty) {
        final String singleLetter = option[0].toUpperCase();
        if (!uniqueLetters.contains(singleLetter)) {
          uniqueLetters.add(singleLetter);
        }
      }
    }
  }

  /// Schedules a scroll jump so the selected item is visible when the panel opens.
  void _scheduleScrollToSelectedItem() {
    if (widget.selectedItem.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        indexToScrollTo = widget.options.indexOf(widget.selectedItem);
        if (indexToScrollTo != -1) {
          indexToScrollTo = max(0, indexToScrollTo - _scrollOffsetItems);
          _scrollController.jumpTo(indexToScrollTo * widget.itemHeight);
        }
      });
    }
  }
}
