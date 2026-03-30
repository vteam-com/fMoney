import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/widgets/pure/gaps.dart';
import 'package:money/widgets/pure/working.dart';

const double _processingMaxWidthFactor = 0.70;
const double _bubbleVerticalMargin = 4.0;
const double _bubblePadding = 12.0;
const double _bubbleRadius = 16.0;
const double _processingTailRadius = 4.0;
const double _processingIndicatorSize = 20.0;

/// A stateless widget for processing indicator.
class ProcessingIndicator extends StatelessWidget {
  const ProcessingIndicator({super.key});

  /// Builds the processing indicator bubble.
  @override
  Widget build(final BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: _bubbleVerticalMargin),
        padding: const EdgeInsets.all(_bubblePadding),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * _processingMaxWidthFactor,
        ),
        decoration: BoxDecoration(
          color: getColorTheme(context).surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(_bubbleRadius),
            topRight: Radius.circular(_bubbleRadius),
            bottomLeft: Radius.circular(_processingTailRadius),
            bottomRight: Radius.circular(_bubbleRadius),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              AppL10n.tr(AppTranslationKeys.thinking),
              style: TextStyle(
                color: getColorTheme(context).onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            gapLarge(),
            const WorkingIndicator(size: _processingIndicatorSize),
          ],
        ),
      ),
    );
  }
}
