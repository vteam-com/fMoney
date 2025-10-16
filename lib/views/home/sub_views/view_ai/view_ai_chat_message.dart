import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:money/core/helpers/color_helper.dart';
import 'package:money/core/helpers/date_helper.dart';
import 'package:money/core/widgets/gaps.dart';
import 'package:money/core/widgets/working.dart';
import 'package:money/data/models/fields/field_filters.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai_chat_message_footer.dart';

enum ChatFrom { user, ai }

class ChatMessage {
  ChatMessage({
    required this.message,
    required this.type,
    required this.timestamp,
    required this.payloadSentToOllama,
    this.isExpanded = false,
  });

  final String message;
  final ChatFrom type;
  final DateTime timestamp;
  final Map<String, dynamic> payloadSentToOllama;
  bool isExpanded;
}

class ChatMessageWidget extends StatefulWidget {
  const ChatMessageWidget({
    super.key,
    required this.message,
    required this.onToggleExpanded,
  });

  final ChatMessage message;
  final VoidCallback onToggleExpanded;

  @override
  State<ChatMessageWidget> createState() => ChatMessageWidgetState();
}

class ChatMessageWidgetState extends State<ChatMessageWidget> {
  @override
  Widget build(final BuildContext context) {
    final ChatMessage message = widget.message;
    final bool isUser = message.type == ChatFrom.user;

    // Only apply truncation to AI messages, not user messages
    final bool shouldTruncate = message.message.trim().split('\n').length > 100;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            // Message bubble
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
                  bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(3),
                  bottomRight: isUser ? const Radius.circular(3) : const Radius.circular(16),
                ),
              ),
              child: IntrinsicWidth(
                child: Column(
                  children: <Widget>[
                    SelectableText(
                      shouldTruncate && !message.isExpanded
                          ? '${message.message.trim().split('\n').take(50).join('\n')}\n...'
                          : message.message.trim(),
                      style: TextStyle(
                        color: isUser ? getColorTheme(context).onPrimaryContainer : getColorTheme(context).onSurface,
                      ),
                    ),
                    Divider(color: getColorTheme(context).onPrimaryContainer.withAlpha(60)),
                    Opacity(
                      opacity: 0.7,
                      child: ChatMessageFooter(
                        message: message,
                        onToggleExpanded: widget.onToggleExpanded,
                        onViewDetails: _showMessageDetails,
                        shouldTruncate: shouldTruncate,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer with read more/less, time, copy, and details
          ],
        ),
      ),
    );
  }

  void _showMessageDetails() {
    final bool isUser = widget.message.type == ChatFrom.user;

    if (isUser) {
      // Show prompt details for user messages
      _showPromptPopup(widget.message.payloadSentToOllama);
    } else {
      // Show message details for AI messages
      showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Message Details'),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.6,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Timestamp: ${widget.message.timestamp.toString()}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    gapMedium(),
                    Text(
                      'Elapsed: ${getElapsedTime(widget.message.timestamp)}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    gapMedium(),
                    const Text(
                      'Content:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    gapSmall(),
                    SelectableText(widget.message.message),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              IconButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: widget.message.message));
                },
                icon: const Icon(Icons.copy_all),
                tooltip: 'Copy message',
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  void _showPromptPopup(final Map<String, dynamic> jsonAsTextpayloadSentToOllama) {
    final String jsonAsText = const JsonEncoder.withIndent('  ').convert(jsonAsTextpayloadSentToOllama);

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Full Prompt Sent to AI'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            child: SingleChildScrollView(
              child: SelectableText(
                jsonAsText,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: <Widget>[
            IconButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: jsonAsText));
              },
              icon: const Icon(Icons.copy),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
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
