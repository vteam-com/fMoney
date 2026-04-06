import 'package:flutter/material.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:money/widgets/pure/scale_down_widget.dart';

const double _segmentVisualDensity = -4.0;
const double _segmentHorizontalPadding = 12.0;

/// Builds a segmented control with customizable direction and icons.
Widget mySegmentSelector({
  required BuildContext context,
  required List<ButtonSegment<int>> segments,
  required final int selectedId,

  /// returns the new selected segment ID
  required void Function(int) onSelectionChanged,
  final Axis direction = Axis.horizontal,
  final bool? showSelectedIcon,
}) {
  final bool shouldShowSelectedIcon = showSelectedIcon ?? context.isWidthLarge;

  if (direction == Axis.horizontal) {
    return SegmentedButton<int>(
      style: const ButtonStyle(
        visualDensity: VisualDensity(horizontal: _segmentVisualDensity, vertical: _segmentVisualDensity),
      ),

      // only show the checkMark for larger devices
      showSelectedIcon: shouldShowSelectedIcon,
      segments: segments,
      selected: <int>{selectedId},
      onSelectionChanged: (final Set<int> newSelection) {
        onSelectionChanged(newSelection.first);
      },
    );
  } else {
    // Vertical orientation - use Column of buttons
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: segments.map<Widget>((final ButtonSegment<int> segment) {
        final bool isSelected = segment.value == selectedId;
        return TextButton(
          onPressed: () => onSelectionChanged(segment.value),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>((final Set<WidgetState> _) {
              if (isSelected) {
                return Theme.of(context).colorScheme.primaryContainer;
              }
              return Colors.transparent;
            }),
            foregroundColor: WidgetStateProperty.resolveWith<Color>((final Set<WidgetState> _) {
              if (isSelected) {
                return Theme.of(context).colorScheme.onPrimaryContainer;
              }
              return Theme.of(context).colorScheme.onSurface;
            }),
            visualDensity: const VisualDensity(
              horizontal: _segmentVisualDensity,
              vertical: _segmentVisualDensity,
            ),
            padding: const WidgetStatePropertyAll<EdgeInsetsGeometry?>(
              EdgeInsets.symmetric(
                horizontal: _segmentHorizontalPadding,
                vertical: SizeForPadding.normal,
              ),
            ),
          ),
          child: segment.icon != null && segment.label != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    segment.icon!,
                    gapSmall(),
                    segment.label!,
                  ],
                )
              : (segment.icon ?? segment.label!),
        );
      }).toList(),
    );
  }
}
