import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';

const double _inputPadding = 16.0;
const double _inputSpacing = 8.0;
const int _outlineAlpha = 100;
const double _inputRadius = 24.0;
const double _inputHorizontalPadding = 16.0;
const double _inputVerticalPadding = 12.0;

/// A stateful widget for chat input area.
class ChatInputArea extends StatefulWidget {
  const ChatInputArea({
    super.key,

    required this.onSendPrompt,
    required this.isProcessing,
    required this.onCancel,
    required this.inputController,
    required this.onTeachAI,
  });

  /// Controls the text input for the prompt.
  final TextEditingController inputController;

  /// Whether the AI is currently processing a request.
  final bool isProcessing;

  /// Called to cancel the current request.
  final VoidCallback onCancel;

  /// Called when the user sends a prompt.
  final ValueChanged<String> onSendPrompt;

  /// Called when the user triggers the teach/seed action.
  final VoidCallback onTeachAI;

  /// Creates state for the chat input area.
  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

/// Special keyword to indicate transaction-related prompts.
const String chatKeywordTransaction = '#transaction';

class _ChatInputAreaState extends State<ChatInputArea> {
  /// Builds the input area with quick prompts and send/cancel actions.
  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_inputPadding),
      decoration: BoxDecoration(
        color: getColorTheme(context).surfaceContainer,
        border: Border(
          top: BorderSide(color: getColorTheme(context).outline.withAlpha(_outlineAlpha)),
        ),
      ),
      child: Column(
        spacing: _inputSpacing,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: _inputSpacing,
            runSpacing: _inputSpacing,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  widget.onSendPrompt('List all the account names');
                },
                child: Text(AppL10n.tr(AppTranslationKeys.accountNames)),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onSendPrompt('Identify the largest single transaction amount in each account');
                },
                child: Text(AppL10n.tr(AppTranslationKeys.largestTransactions)),
              ),
              ElevatedButton(
                onPressed: () => widget.onSendPrompt('Analyze my spending patterns'),
                child: Text(AppL10n.tr(AppTranslationKeys.analyzeSpending)),
              ),
              ElevatedButton(
                onPressed: () => widget.onSendPrompt('Predict future expenses'),
                child: Text(AppL10n.tr(AppTranslationKeys.expensePredictions)),
              ),
            ],
          ),
          Row(
            spacing: _inputSpacing,
            children: <Widget>[
              OutlinedButton(
                onPressed: () {
                  widget.onTeachAI();
                },
                child: Text(AppL10n.tr(AppTranslationKeys.bankaccounts)),
              ),
              Expanded(
                child: TextField(
                  controller: widget.inputController,
                  decoration: InputDecoration(
                    hintText: 'Ask the AI assistant...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(_inputRadius),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: _inputHorizontalPadding,
                      vertical: _inputVerticalPadding,
                    ),
                    filled: true,
                    fillColor: getColorTheme(context).surface,
                  ),
                  onSubmitted: widget.onSendPrompt,
                ),
              ),

              if (widget.isProcessing)
                IconButton(
                  onPressed: widget.onCancel,
                  icon: Icon(Icons.cancel, color: getColorTheme(context).primary),
                )
              else
                IconButton(
                  onPressed: () {
                    final String text = widget.inputController.text;
                    if (text.isNotEmpty) {
                      widget.onSendPrompt(text);
                    }
                  },
                  icon: Icon(Icons.send, color: getColorTheme(context).primary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
