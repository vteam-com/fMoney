import 'dart:math';

import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/widgets/columns/column_content_center_widget.dart';

const double _headerHorizontalPadding = 3;
const double _sortIconSize = 20;

/// Builds a column header button with optional sorting/filter indicators.
Widget buildColumnHeaderButton({
  required BuildContext context,
  required String text,
  TextAlign textAlign = TextAlign.left,
  SortIndicator sortIndicator = SortIndicator.none,
  int flex = 1,
  bool hasFilters = false,
  VoidCallback? onPressed,
  VoidCallback? onLongPress,
}) {
  return Expanded(
    flex: flex,
    child: Tooltip(
      message: '$text${SharedStrings.lineFeed}${_getTooltipText(sortIndicator, hasFilters)}'.trim(),
      child: TextButton(
        style: ButtonStyle(
          shape: WidgetStateProperty.all<OutlinedBorder>(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // Remove rounded corners
            ),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(
              horizontal: _headerHorizontalPadding, // Left and right padding
            ),
          ),
        ),
        onPressed: onPressed,
        onLongPress: onLongPress,
        // clipBehavior: Clip.hardEdge,
        child: _buildTextAndSortAndFilter(
          context,
          textAlign,
          text,
          _buildAdorners(sortIndicator, hasFilters),
        ),
      ),
    ),
  );
}

/// Builds the header content row with alignment and optional sort/filter adorners.
Widget _buildTextAndSortAndFilter(
  BuildContext context,
  TextAlign align,
  final String text,
  final Widget adorner,
) {
  switch (align) {
    case TextAlign.center:
      return HeaderContentCenter(text: text, trailingWidget: adorner);

    case TextAlign.right:
    case TextAlign.end:
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Text(
              text,
              softWrap: false,
              textAlign: TextAlign.right,
              overflow: TextOverflow.clip,
              style: getTextTheme(
                context,
              ).labelSmall!.copyWith(color: getColorTheme(context).secondary),
            ),
          ),
          adorner,
        ],
      );

    case TextAlign.left:
    case TextAlign.start:
    default:
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text(
            text,
            softWrap: false,
            textAlign: TextAlign.left,
            overflow: TextOverflow.clip,
            style: getTextTheme(
              context,
            ).labelSmall!.copyWith(color: getColorTheme(context).secondary),
          ),
          adorner,
        ],
      );
  }
}

/// Builds the trailing adorners for a header cell.
Widget _buildAdorners(
  final SortIndicator sortIndicator,
  final bool hasFilters,
) {
  return Row(
    children: <Widget>[
      buildSortIconNameWidget(sortIndicator),
      _buildAdornerFoFilter(hasFilters),
    ],
  );
}

/// Builds a sort icon widget with optional rotation for ascending state.
Widget buildSortIconNameWidget(final SortIndicator sortIndicator) {
  switch (sortIndicator) {
    case SortIndicator.sortAscending:
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationX(pi), // Rotate 180 degrees on both X and Y axes
        child: const Icon(
          Icons.sort,
          size: _sortIconSize,
        ), // Rotate 180 degrees for descending
      );
    case SortIndicator.sortDescending:
      return const Icon(Icons.sort, size: _sortIconSize);
    case SortIndicator.none:
      return const SizedBox();
  }
}

/// Builds the filter icon adorner when filtering is active.
Widget _buildAdornerFoFilter(final bool filterOn) {
  if (filterOn) {
    return const Icon(Icons.filter_alt_outlined, size: _sortIconSize);
  }
  return const SizedBox();
}

/// Builds tooltip text describing the current sorting and filtering state.
String _getTooltipText(final SortIndicator sortIndicator, final bool filterOn) {
  String tooltip = filterOn ? '${SharedStrings.labelFiltering}${SharedStrings.lineFeed}' : '';

  switch (sortIndicator) {
    case SortIndicator.sortAscending:
      tooltip += SharedStrings.labelSortingAscending;
    case SortIndicator.sortDescending:
      tooltip += SharedStrings.labelSortingDescending;
    case SortIndicator.none:
      break;
  }
  return tooltip;
}

enum SortIndicator { none, sortAscending, sortDescending }

/// Returns a SortIndicator based on current sort and target column.
SortIndicator getSortIndicator(
  final int currentSort,
  final int sortToMatch,
  final bool ascending,
) {
  if (sortToMatch == currentSort) {
    return ascending ? SortIndicator.sortAscending : SortIndicator.sortDescending;
  }
  return SortIndicator.none;
}
