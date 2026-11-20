import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/widgets/dialogs/dialog_button.dart';
import 'package:money/widgets/pure/gaps_helper.dart';

/// Widest the dialog content grows, so long detail lines wrap instead of stretching it.
const double _maxContentWidth = 560.0;

/// Asks the user whether to apply a change the AI proposes: [summary] says what changes and [details]
/// lists the rows it touches. Returns true only when the user picks Apply.
///
/// Applying only makes pending in-memory edits; the dialog says so, and saving stays the user's call.
Future<bool> showAiChangeConfirmDialog(
  BuildContext context, {
  required String summary,
  required List<String> details,
}) async {
  final bool? applied = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) => AlertDialog(
      title: Text(AppL10n.tr(AppTranslationKeys.aiConfirmChangeTitle)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(summary, style: Theme.of(dialogContext).textTheme.titleSmall),
              gapMedium(),
              for (final String line in details) Text(line),
              gapLarge(),
              Text(
                AppL10n.tr(AppTranslationKeys.aiConfirmChangePendingNote),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        DialogActionButton(
          text: AppL10n.tr(AppTranslationKeys.cancel),
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        DialogActionButton(
          text: AppL10n.tr(AppTranslationKeys.apply),
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return applied ?? false;
}
