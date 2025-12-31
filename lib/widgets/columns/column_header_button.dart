import 'package:money/helpers/color_helper.dart';
import 'package:money/widgets/columns/column_content_center.dart';

// Exports
export 'package:flutter/material.dart';

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
      message: '$text\n${_getTooltipText(sortIndicator, hasFilters)}'.trim(),
      child: TextButton(
        style: ButtonStyle(
          shape: WidgetStateProperty.all<OutlinedBorder>(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero, // Remove rounded corners
            ),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(
              horizontal: 3.0, // Left and right padding
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

Widget buildSortIconNameWidget(final SortIndicator sortIndicator) {
  switch (sortIndicator) {
    case SortIndicator.sortAscending:
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationX(
          3.14159,
        ), // Rotate 180 degrees on both X and Y axes
        child: const Icon(
          Icons.sort,
          size: 20.0,
        ), // Rotate 180 degrees for descending
      );
    case SortIndicator.sortDescending:
      return const Icon(Icons.sort, size: 20.0);
    case SortIndicator.none:
      return const SizedBox();
  }
}

Widget _buildAdornerFoFilter(final bool filterOn) {
  if (filterOn) {
    return const Icon(Icons.filter_alt_outlined, size: 20.0);
  }
  return const SizedBox();
}

String _getTooltipText(final SortIndicator sortIndicator, final bool filterOn) {
  String tooltip = filterOn ? 'Filtering\n' : '';

  switch (sortIndicator) {
    case SortIndicator.sortAscending:
      tooltip += 'Sorting Ascending';
    case SortIndicator.sortDescending:
      tooltip += 'Sorting Descending';
    case SortIndicator.none:
      break;
  }
  return tooltip;
}

enum SortIndicator { none, sortAscending, sortDescending }

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
