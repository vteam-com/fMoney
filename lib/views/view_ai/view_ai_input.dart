import 'package:money/helpers/color_helper.dart';

const double _inputPadding = 16.0;
const double _inputSpacing = 8.0;
const int _outlineAlpha = 100;
const double _inputRadius = 24.0;
const double _inputHorizontalPadding = 16.0;
const double _inputVerticalPadding = 12.0;

class ChatInputArea extends StatefulWidget {
  const ChatInputArea({
    super.key,

    required this.onSendPrompt,
    required this.isProcessing,
    required this.onCancel,
    required this.inputController,
    required this.onTeachAI,
  });

  final TextEditingController inputController;

  final bool isProcessing;

  final VoidCallback onCancel;

  final ValueChanged<String> onSendPrompt;

  final VoidCallback onTeachAI;

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

const String chatKeywordTransaction = '#transaction';

class _ChatInputAreaState extends State<ChatInputArea> {
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
                child: const Text('Account names'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onSendPrompt('Identify the largest single transaction amount in each account');
                },
                child: const Text('Largest transactions'),
              ),
              ElevatedButton(
                onPressed: () => widget.onSendPrompt('Analyze my spending patterns'),
                child: const Text('Analyze spending'),
              ),
              ElevatedButton(
                onPressed: () => widget.onSendPrompt('Predict future expenses'),
                child: const Text('Expense predictions'),
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
                child: const Text('BankAccounts'),
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
