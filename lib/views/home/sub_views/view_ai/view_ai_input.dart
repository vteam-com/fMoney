import 'package:money/data/storage/data/data.dart';

class ChatInputArea extends StatefulWidget {
  const ChatInputArea({
    super.key,

    required this.onSendPrompt,
    required this.isProcessing,
    required this.onCancel,
    required this.inputController,
    required this.onTeachAI,
  });

  final ValueChanged<String> onSendPrompt;
  final bool isProcessing;
  final VoidCallback onCancel;
  final VoidCallback onTeachAI;
  final TextEditingController inputController;

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

const String chatKeywordTransaction = '#transaction';

class _ChatInputAreaState extends State<ChatInputArea> {
  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: getColorTheme(context).surfaceContainer,
        border: Border(
          top: BorderSide(color: getColorTheme(context).outline.withAlpha(100)),
        ),
      ),
      child: Column(
        spacing: 8,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
            spacing: 8,
            children: <Widget>[
              OutlinedButton(
                onPressed: () {
                  widget.onTeachAI();
                },
                child: const Text('Transactions'),
              ),
              Expanded(
                child: TextField(
                  controller: widget.inputController,
                  decoration: InputDecoration(
                    hintText: 'Ask the AI assistant...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
