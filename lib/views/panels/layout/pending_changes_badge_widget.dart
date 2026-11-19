import 'package:material_ui/material_ui.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/views/panels/dialogs/pending_changes_dialog.dart';
import 'package:money/widgets/dialogs/mutation_type_display_helper.dart';

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

  /// Returns how many changes of [type] this badge reports.
  int countOf(MutationType type) => switch (type) {
    MutationType.inserted => itemsAdded,
    MutationType.changed => itemsChanged,
    MutationType.deleted => itemsDeleted,
    _ => _zeroInt,
  };

  /// Returns a label widget indicating the type of pending changes.
  Widget getChangeLabel(BuildContext context) {
    final TextStyle textStyle = Theme.of(
      context,
    ).textTheme.labelSmall!.copyWith(fontSize: _counterFontSize, fontWeight: FontWeight.w900);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (final MutationType type in pendingMutationTypes)
          if (countOf(type) > _zeroInt)
            buildCounter(type.prefix, countOf(type), textStyle.copyWith(color: type.getColor(context))),
      ],
    );
  }

  /// Returns a tooltip text string that summarizes the pending changes, including the number of added, modified, and deleted items, as well as the last time the changes were edited.
  String getTooltipText() {
    final String lastChangedOn = getElapsedTime(
      DataFileController.to.trackMutations.lastDateTimeChanged,
    );
    final String counts = pendingMutationTypes
        .map((MutationType type) => '${AppL10n.tr(type.labelKey)}: ${countOf(type)}')
        .join(SharedStrings.lineFeed);
    return '$counts'
        '${SharedStrings.lineFeed}${SharedStrings.lineFeed}'
        '${AppL10n.tr(AppTranslationKeys.editedElapsed, params: <String, String>{'elapsed': lastChangedOn})}';
  }
}

/// Builds the pending changes badge of [dataController], rebuilt whenever its tracked changes do.
Widget buildPendingChangesBadge(DataFileController dataController) {
  return ListenableBuilder(
    listenable: dataController.trackMutations,
    builder: (BuildContext _, Widget? _) {
      return BadgePendingChanges(
        key: Constants.keyPendingChanges,
        itemsAdded: dataController.trackMutations.added,
        itemsChanged: dataController.trackMutations.changed,
        itemsDeleted: dataController.trackMutations.deleted,
      );
    },
  );
}
