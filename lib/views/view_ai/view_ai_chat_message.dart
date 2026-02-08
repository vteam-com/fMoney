import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/views/view_ai/view_ai_chat_message_footer.dart';
import 'package:money/views/view_ai/view_ai_chat_types.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/working.dart';

const int _maxLinesBeforeTruncate = 100;
const int _truncatePreviewLines = 50;
const double _bubbleMaxWidthFactor = 0.50;
const double _processingMaxWidthFactor = 0.70;
const double _detailsWidthFactor = 0.8;
const double _detailsHeightFactor = 0.6;
const double _bubbleVerticalMargin = 4.0;
const double _bubblePadding = 12.0;
const double _bubbleRadius = 16.0;
const double _bubbleTailRadius = 3.0;
const double _processingTailRadius = 4.0;
const int _dividerAlpha = 60;
const double _footerOpacity = 0.7;
const double _monospaceFontSize = 12.0;
const double _processingIndicatorSize = 20.0;

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
    final bool shouldTruncate = message.message.trim().split('\n').length > _maxLinesBeforeTruncate;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * _bubbleMaxWidthFactor,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            // Message bubble
            Container(
              margin: const EdgeInsets.symmetric(vertical: _bubbleVerticalMargin),
              padding: const EdgeInsets.all(_bubblePadding),
              decoration: BoxDecoration(
                color: isUser
                    ? getColorTheme(context).primaryContainer
                    : getColorTheme(context).surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(_bubbleRadius),
                  topRight: const Radius.circular(_bubbleRadius),
                  bottomLeft: isUser ? const Radius.circular(_bubbleRadius) : const Radius.circular(_bubbleTailRadius),
                  bottomRight: isUser ? const Radius.circular(_bubbleTailRadius) : const Radius.circular(_bubbleRadius),
                ),
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  MarkdownBody(
                    data: shouldTruncate && !message.isExpanded
                        ? '${message.message.trim().split('\n').take(_truncatePreviewLines).join('\n')}\n...'
                        : message.message.trim(),
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isUser ? getColorTheme(context).onPrimaryContainer : getColorTheme(context).onSurface,
                      ),
                    ),
                    selectable: true,
                  ),
                  Divider(color: getColorTheme(context).onPrimaryContainer.withAlpha(_dividerAlpha)),
                  Opacity(
                    opacity: _footerOpacity,
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
              width: MediaQuery.of(context).size.width * _detailsWidthFactor,
              height: MediaQuery.of(context).size.height * _detailsHeightFactor,
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

  void _showPromptPopup(final Map<String, dynamic> jsonAsTextPayloadSentToOllama) {
    final String jsonAsText = const JsonEncoder.withIndent('  ').convert(jsonAsTextPayloadSentToOllama);

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Full Prompt Sent to AI'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * _detailsWidthFactor,
            height: MediaQuery.of(context).size.height * _detailsHeightFactor,
            child: SingleChildScrollView(
              child: SelectableText(
                jsonAsText,
                style: const TextStyle(fontFamily: 'monospace', fontSize: _monospaceFontSize),
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
              'Thinking...',
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
