import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:money/core/helpers/color_helper.dart';
import 'package:money/core/widgets/gaps.dart';
import 'package:money/core/widgets/working.dart';
import 'package:money/data/models/fields/field_filters.dart';

enum MessageType { user, ai }

class ChatMessage {
  ChatMessage({
    required this.message,
    required this.type,
    required this.timestamp,
    required this.payloadSentToOllama,
    this.isExpanded = false,
  });

  final String message;
  final MessageType type;
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
    final bool isUser = message.type == MessageType.user;

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
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IntrinsicWidth(
                    child: SelectableText(
                      shouldTruncate && !message.isExpanded
                          ? '${message.message.trim().split('\n').take(50).join('\n')}\n...'
                          : message.message.trim(),
                      style: TextStyle(
                        color: isUser ? getColorTheme(context).onPrimaryContainer : getColorTheme(context).onSurface,
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 16,
                    children: <Widget>[
                      if (shouldTruncate)
                        TextButton(
                          onPressed: widget.onToggleExpanded,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            textAlign: TextAlign.start,
                            message.isExpanded ? 'Read Less' : 'Read More',
                            style: TextStyle(
                              color: getColorTheme(context).primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      Opacity(opacity: 0.5, child: Text(getElapsedTime(message.timestamp))),
                      if (isUser)
                        IconButton(
                          onPressed: () => _showPromptPopup(message.payloadSentToOllama),
                          icon: Icon(
                            Icons.comment,
                            color: getColorTheme(context).primary.withAlpha(200),
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            maxWidth: 24,
                            maxHeight: 24,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
              icon: const Icon(Icons.copy_all),
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
