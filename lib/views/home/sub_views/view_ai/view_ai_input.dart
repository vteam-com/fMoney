// ignore_for_file: avoid_print

import 'package:money/core/widgets/my_segment.dart';
import 'package:money/data/storage/data/data.dart';

class ChatInputArea extends StatefulWidget {
  const ChatInputArea({
    super.key,
    required this.contextMode,
    required this.onContextModeChanged,
    required this.onSendPrompt,
    required this.isProcessing,
    required this.onCancel,
  });

  final int contextMode;
  final ValueChanged<int> onContextModeChanged;
  final ValueChanged<String> onSendPrompt;
  final bool isProcessing;
  final VoidCallback onCancel;

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(final BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: getColorTheme(context).outline.withAlpha(100)),
        ),
      ),
      child: Column(
        spacing: 8,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 600,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () => widget.onSendPrompt('Analyze my spending patterns'),
                  child: const Text('Analyze spending'),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.onContextModeChanged(1);
                    widget.onSendPrompt('Identify the largest single transaction amount in each account');
                  },
                  child: const Text('Largest transactions'),
                ),
                ElevatedButton(
                  onPressed: () => widget.onSendPrompt('Predict future expenses'),
                  child: const Text('Expense predictions'),
                ),
              ],
            ),
          ),
          Row(
            spacing: 8,
            children: <Widget>[
              SizedBox(
                width: 100,
                child: mySegmentSelector(
                  direction: Axis.vertical,
                  showSelectedIcon: false,
                  segments: <ButtonSegment<int>>[
                    const ButtonSegment<int>(
                      value: 0,
                      label: Text('Generic'),
                    ),
                    const ButtonSegment<int>(
                      value: 1,
                      label: Text('All data'),
                    ),
                  ],
                  selectedId: widget.contextMode,
                  onSelectionChanged: widget.onContextModeChanged,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Ask the AI assistant...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    final String text = _textController.text;
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
