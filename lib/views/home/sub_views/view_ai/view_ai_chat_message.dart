import 'package:money/core/helpers/color_helper.dart';
import 'package:money/core/widgets/gaps.dart';
import 'package:money/core/widgets/working.dart';

enum MessageType { user, ai }

class ChatMessage {
  ChatMessage({
    required this.message,
    required this.type,
    required this.timestamp,
    required this.payloadSentToOllama,
    this.contextMode = 0,
    this.isExpanded = false,
  });

  final String message;
  final MessageType type;
  final DateTime timestamp;
  final Map<String, dynamic> payloadSentToOllama;
  final int contextMode;
  bool isExpanded;
}

class ChatMessageWidget extends StatefulWidget {
  const ChatMessageWidget({
    super.key,
    required this.message,
    required this.onToggleExpanded,
    required this.onShowPromptPopup,
  });

  final ChatMessage message;
  final VoidCallback onToggleExpanded;
  final ValueChanged<Map<String, dynamic>> onShowPromptPopup;

  @override
  State<ChatMessageWidget> createState() => ChatMessageWidgetState();
}

class ChatMessageWidgetState extends State<ChatMessageWidget> {
  @override
  Widget build(final BuildContext context) {
    final ChatMessage message = widget.message;
    final bool isUser = message.type == MessageType.user;

    // Only apply truncation to AI messages, not user messages
    final bool shouldTruncate = !isUser && message.message.trim().split('\n').length > 100;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            if (isUser)
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Icon(
                    message.contextMode == 0 ? Icons.chat_bubble_outline : Icons.data_object,
                    color: getColorTheme(context).primary,
                    size: 16,
                  ),
                  gapSmall(),
                  Text(
                    message.contextMode == 0 ? 'Generic' : 'Data context',
                    style: TextStyle(
                      color: getColorTheme(context).primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  ...<Widget>[
                    gapSmall(),
                    IconButton(
                      onPressed: () => widget.onShowPromptPopup(message.payloadSentToOllama),
                      icon: Icon(
                        Icons.info_outline,
                        color: getColorTheme(context).primary,
                        size: 16,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        maxWidth: 24,
                        maxHeight: 24,
                      ),
                    ),
                  ],
                ],
              ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? getColorTheme(context).primaryContainer
                    : getColorTheme(context).surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SelectableText(
                    shouldTruncate && !message.isExpanded
                        ? '${message.message.trim().split('\n').take(100).join('\n')}\n...'
                        : message.message.trim(),
                    style: TextStyle(
                      color: isUser ? getColorTheme(context).onPrimaryContainer : getColorTheme(context).onSurface,
                    ),
                  ),
                  if (shouldTruncate)
                    TextButton(
                      onPressed: widget.onToggleExpanded,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        message.isExpanded ? 'Read Less' : 'Read More',
                        style: TextStyle(
                          color: getColorTheme(context).primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProcessingIndicator extends StatelessWidget {
  const ProcessingIndicator({super.key});

  @override
  Widget build(final BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: getColorTheme(context).surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Thinking...',
              style: TextStyle(
                color: getColorTheme(context).onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            gapLarge(),
            const WorkingIndicator(size: 20),
          ],
        ),
      ),
    );
  }
}
