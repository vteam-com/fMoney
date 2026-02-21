import 'package:flutter/material.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/views/data_file_controller.dart';
import 'package:money/views/panels/pending_changes/pending_changes_dialog.dart';

const int _zeroInt = 0;
const double _badgePadding = 0.0;
const double _badgeRadius = 4.0;
const double _counterPadding = 3.0;
const double _counterFontSize = 9.0;

///
class BadgePendingChanges extends StatelessWidget {
  /// Constructor
  const BadgePendingChanges({
    super.key,
    required this.itemsAdded,
    required this.itemsChanged,
    required this.itemsDeleted,
  });

  final int itemsAdded;
  final int itemsChanged;
  final int itemsDeleted;

  @override
  Widget build(final BuildContext context) {
    if (itemsAdded == _zeroInt && itemsChanged == _zeroInt && itemsDeleted == _zeroInt) {
      // not change to report
      return const SizedBox();
    }

    return Tooltip(
      message: getTooltipText(),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(_badgePadding),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_badgeRadius),
          ),
          backgroundColor: Colors.white,
        ),
        onPressed: () {
          PendingChangesDialog.show(context);
        },
        child: getChangeLabel(context),
      ),
    );
  }

  /// Builds a counter widget with prefix, value, and text style.
  Widget buildCounter(
    final String prefix,
    final int value,
    final TextStyle textStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _counterPadding),
      child: Text(prefix + getIntAsText(value), style: textStyle),
    );
  }

  /// Returns a label widget indicating the type of pending changes.
  Widget getChangeLabel(final BuildContext context) {
    final List<Widget> widgets = <Widget>[];
    final TextStyle textStyle = Theme.of(
      context,
    ).textTheme.labelSmall!.copyWith(fontSize: _counterFontSize, fontWeight: FontWeight.w900);
    if (DataFileController.to.trackMutations.added.value > _zeroInt) {
      widgets.add(
        buildCounter(
          '+',
          DataFileController.to.trackMutations.added.value,
          textStyle.copyWith(color: Colors.green),
        ),
      );
    }

    if (DataFileController.to.trackMutations.changed.value > _zeroInt) {
      widgets.add(
        buildCounter(
          '=',
          DataFileController.to.trackMutations.changed.value,
          textStyle.copyWith(color: Colors.orange),
        ),
      );
    }

    if (DataFileController.to.trackMutations.deleted.value > _zeroInt) {
      widgets.add(
        buildCounter(
          '-',
          DataFileController.to.trackMutations.deleted.value,
          textStyle.copyWith(color: Colors.red),
        ),
      );
    }

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: widgets);
  }

  /// Returns a tooltip text string that summarizes the pending changes, including the number of added, modified, and deleted items, as well as the last time the changes were edited.
  String getTooltipText() {
    final String lastChangedOn = getElapsedTime(
      DataFileController.to.trackMutations.lastDateTimeChanged.value,
    );
    return 'Added: ${DataFileController.to.trackMutations.added}\nModified: ${DataFileController.to.trackMutations.changed}\nDeleted: ${DataFileController.to.trackMutations.deleted}\n\nEdited $lastChangedOn';
  }
}
