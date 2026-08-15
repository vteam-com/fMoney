import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/views/panels/dialogs/pending_changes_dialog.dart';

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
  Widget build(BuildContext context) {
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
    String prefix,
    int value,
    TextStyle textStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _counterPadding),
      child: Text(prefix + getIntAsText(value), style: textStyle),
    );
  }

  /// Returns a label widget indicating the type of pending changes.
  Widget getChangeLabel(BuildContext context) {
    final List<Widget> widgets = <Widget>[];
    final TextStyle textStyle = Theme.of(
      context,
    ).textTheme.labelSmall!.copyWith(fontSize: _counterFontSize, fontWeight: FontWeight.w900);
    if (DataFileController.to.trackMutations.added > _zeroInt) {
      widgets.add(
        buildCounter(
          '+',
          DataFileController.to.trackMutations.added,
          textStyle.copyWith(color: Colors.green),
        ),
      );
    }

    if (DataFileController.to.trackMutations.changed > _zeroInt) {
      widgets.add(
        buildCounter(
          '=',
          DataFileController.to.trackMutations.changed,
          textStyle.copyWith(color: Colors.orange),
        ),
      );
    }

    if (DataFileController.to.trackMutations.deleted > _zeroInt) {
      widgets.add(
        buildCounter(
          '-',
          DataFileController.to.trackMutations.deleted,
          textStyle.copyWith(color: Colors.red),
        ),
      );
    }

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: widgets);
  }

  /// Returns a tooltip text string that summarizes the pending changes, including the number of added, modified, and deleted items, as well as the last time the changes were edited.
  String getTooltipText() {
    final String lastChangedOn = getElapsedTime(
      DataFileController.to.trackMutations.lastDateTimeChanged,
    );
    return '${AppL10n.tr(AppTranslationKeys.mutationAdded)}: ${DataFileController.to.trackMutations.added}'
        '${SharedStrings.lineFeed}'
        '${AppL10n.tr(AppTranslationKeys.mutationModified)}: ${DataFileController.to.trackMutations.changed}'
        '${SharedStrings.lineFeed}'
        '${AppL10n.tr(AppTranslationKeys.mutationDeleted)}: ${DataFileController.to.trackMutations.deleted}'
        '${SharedStrings.lineFeed}${SharedStrings.lineFeed}'
        '${AppL10n.tr(AppTranslationKeys.editedElapsed, params: <String, String>{'elapsed': lastChangedOn})}';
  }
}
