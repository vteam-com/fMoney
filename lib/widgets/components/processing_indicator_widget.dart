import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/widgets/components/chat_bubble_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:money/widgets/pure/working_indicator_widget.dart';

const double _processingMaxWidthFactor = 0.70;
const double _processingIndicatorSize = 20.0;

/// A stateless widget for processing indicator.
class ProcessingIndicator extends StatelessWidget {
  const ProcessingIndicator({super.key});

  /// Builds the processing indicator bubble.
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * _processingMaxWidthFactor,
        ),
        child: ChatBubble(
          color: getColorTheme(context).surfaceContainerHighest,
          isFromUser: false,
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
      ),
    );
  }
}
