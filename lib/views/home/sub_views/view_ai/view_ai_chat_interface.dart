import 'package:money/data/storage/data/data.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai_chat_message.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai_input.dart';

enum MessageType { user, ai }

// Using a const for now, but this should be configurable and loaded dynamically
String modelToUseInOllama = 'martain7r/finance-llama-8b:q4_k_m'; //'gpt-oss:20b',

// Sub-widgets for better organization

class ChatInterface extends StatefulWidget {
  const ChatInterface({
    super.key,
    required this.chatHistory,
    required this.contextMode,
    required this.isProcessing,
    required this.onContextModeChanged,
    required this.onSendPrompt,
    required this.onCancel,
    required this.onToggleExpanded,
    required this.onShowPromptPopup,
  });

  final List<ChatMessage> chatHistory;
  final int contextMode;
  final bool isProcessing;
  final ValueChanged<int> onContextModeChanged;
  final ValueChanged<String> onSendPrompt;
  final VoidCallback onCancel;
  final ValueChanged<int> onToggleExpanded;
  final ValueChanged<Map<String, dynamic>> onShowPromptPopup;

  @override
  State<ChatInterface> createState() => ChatInterfaceState();
}

class ChatInterfaceState extends State<ChatInterface> {
  @override
  Widget build(final BuildContext context) {
    return Container(
      color: getColorTheme(context).surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: false,
              itemCount:
                  widget.chatHistory.length + (widget.isProcessing ? 1 : 0) + (widget.chatHistory.isEmpty ? 1 : 0),
              itemBuilder: (final BuildContext context, final int index) {
                if (widget.chatHistory.isEmpty && !widget.isProcessing) {
                  return const Text('Welcome to your AI Accountant');
                }
                // Handle chat messages
                final int messageIndex = index - (widget.chatHistory.isEmpty ? 1 : 0);

                if (messageIndex < widget.chatHistory.length) {
                  final ChatMessage message = widget.chatHistory[messageIndex];
                  return ChatMessageWidget(
                    message: message,
                    onToggleExpanded: () => widget.onToggleExpanded(messageIndex),
                    onShowPromptPopup: widget.onShowPromptPopup,
                  );
                } else {
                  // Show processing indicator
                  return const ProcessingIndicator();
                }
              },
            ),
          ),

          ChatInputArea(
            contextMode: widget.contextMode,
            onContextModeChanged: widget.onContextModeChanged,
            onSendPrompt: widget.onSendPrompt,
            isProcessing: widget.isProcessing,
            onCancel: widget.onCancel,
          ),
        ],
      ),
    );
  }
}
