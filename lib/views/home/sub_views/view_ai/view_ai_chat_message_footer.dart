import 'package:flutter/services.dart';
import 'package:money/core/helpers/color_helper.dart';
import 'package:money/core/helpers/date_helper.dart';
import 'package:money/data/models/fields/field_filters.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai_chat_message.dart';

class ChatMessageFooter extends StatelessWidget {
  const ChatMessageFooter({
    super.key,
    required this.message,
    required this.onToggleExpanded,
    required this.onViewDetails,
    required this.shouldTruncate,
  });

  final ChatMessage message;
  final VoidCallback onToggleExpanded;
  final VoidCallback onViewDetails;
  final bool shouldTruncate;

  @override
  Widget build(final BuildContext context) {
    final bool isUser = message.type == MessageType.user;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        // Left side: read more/read less and elapsed time
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: <Widget>[
            if (shouldTruncate)
              TextButton(
                onPressed: onToggleExpanded,
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
            Opacity(
              opacity: 0.7,
              child: Text(
                getElapsedTime(message.timestamp),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),

        // Right side: copy and view details
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: <Widget>[
            IconButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: message.message));
              },
              icon: const Icon(Icons.copy, size: 18),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              tooltip: 'Copy message to clipboard',
            ),
            IconButton(
              onPressed: onViewDetails,
              icon: Icon(
                isUser ? Icons.comment : Icons.info,
                size: 18,
              ),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              tooltip: isUser ? 'View prompt details' : 'View message details',
            ),
          ],
        ),
      ],
    );
  }
}
