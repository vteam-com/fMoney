import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/widgets/components/info_banner_widget.dart';
import 'package:money/widgets/pickers/category_picker_widget.dart';
import 'package:money/widgets/pure/box_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';

const double _categoryLabelWidth = 100.0;
const double _actionPadding = 8.0;
const double _actionOfferingWidth = 250.0;

/// A stateful widget for merge categories transactions dialog.
class MergeCategoriesTransactionsDialog extends StatefulWidget {
  const MergeCategoriesTransactionsDialog({
    required this.categoryToMove,
    super.key,
  });

  final Category categoryToMove;

  @override
  State<MergeCategoriesTransactionsDialog> createState() => _MergeCategoriesTransactionsDialogState();
}

class _MergeCategoriesTransactionsDialogState extends State<MergeCategoriesTransactionsDialog> {
  late Category _categoryPicked = widget.categoryToMove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(width: _categoryLabelWidth, child: Text(AppL10n.tr(AppTranslationKeys.fromCategory))),
            Expanded(
              child: Box(child: Text(widget.categoryToMove.fieldName.value)),
            ),
          ],
        ),
        gapLarge(),
        gapLarge(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(width: _categoryLabelWidth, child: Text(AppL10n.tr(AppTranslationKeys.toCategory))),
            Expanded(
              child: Box(
                child: pickerCategory(
                  categoryNames: Data().categories.getCategoriesAsStrings(),
                  selectedName: widget.categoryToMove.fieldName.value,
                  onSelected: (String? name) {
                    final Category? newSelection = name != null ? Data().categories.getByName(name) : null;
                    if (newSelection != null) {
                      setState(() {
                        _categoryPicked = newSelection;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Padding(padding: const EdgeInsets.all(_actionPadding), child: _buildActionPanel()),
        const Spacer(),
      ],
    );
  }

  /// Builds a single action offering with its button and explanatory text.
  Widget _buildActionOffering(String text, Widget action) {
    return SizedBox(
      width: _actionOfferingWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(padding: const EdgeInsets.all(_actionPadding), child: action),
          gapMedium(),
          Text(text),
          gapMedium(),
        ],
      ),
    );
  }

  /// Builds the action panel that offers append or merge operations.
  Widget _buildActionPanel() {
    final String from = widget.categoryToMove.fieldName.value;
    final String to = _categoryPicked.fieldName.value;

    if (from == to) {
      return Center(
        child: InfoBanner.warning(
          AppL10n.tr(
            AppTranslationKeys.pickDifferentCategoryThan,
            params: <String, String>{
              'category': from,
            },
          ),
        ),
      );
    }

    return Center(
      child: Wrap(
        spacing: SizeForPadding.large,
        runSpacing: SizeForPadding.large,
        children: <Widget>[
          // Append
          _buildActionOffering(
            AppL10n.tr(
              AppTranslationKeys.moveCategoryAsChild,
              params: <String, String>{
                'from': from,
                'to': to,
              },
            ),
            OutlinedButton(
              onPressed: () {
                if (_categoryPicked == widget.categoryToMove) {
                  showSnackBar(
                    context,
                    AppL10n.tr(AppTranslationKeys.noNeedToMergeCategoryToItself),
                  );
                } else if (Data().categories.reparentCategory(widget.categoryToMove, _categoryPicked)) {
                  Navigator.pop(context);
                } else {
                  showSnackBar(context, AppL10n.tr(AppTranslationKeys.cannotMoveCategoryUnderItself));
                }
              },
              child: Text(AppL10n.tr(AppTranslationKeys.append)),
            ),
          ),
          gapLarge(),
          // Merge
          _buildActionOffering(
            AppL10n.tr(
              AppTranslationKeys.mergeTransactionsIntoCategory,
              params: <String, String>{
                'from': from,
                'to': to,
              },
            ),
            OutlinedButton(
              onPressed: () {
                if (_categoryPicked == widget.categoryToMove) {
                  showSnackBar(
                    context,
                    AppL10n.tr(AppTranslationKeys.noNeedToMergeCategoryToItself),
                  );
                } else if (Data().mergeCategoryInto(widget.categoryToMove, _categoryPicked)) {
                  Navigator.pop(context);
                } else {
                  showSnackBar(context, AppL10n.tr(AppTranslationKeys.cannotMoveCategoryUnderItself));
                }
              },
              child: Text(AppL10n.tr(AppTranslationKeys.merge)),
            ),
          ),
        ],
      ),
    );
  }
}
