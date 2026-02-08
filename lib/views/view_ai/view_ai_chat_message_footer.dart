import 'package:flutter/services.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/date_helper.dart';
import 'package:money/views/view_ai/view_ai_chat_types.dart';

const double _footerSpacing = 12.0;
const double _footerOpacity = 0.7;
const double _footerIconSpacing = 8.0;
const double _footerFontSize = 12.0;
const double _footerIconSize = 18.0;
const double _footerIconPadding = 4.0;

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
    final bool isUser = message.type == ChatFrom.user;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        // Left side: read more/read less and elapsed time
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: _footerSpacing,
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
                    fontSize: _footerFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Opacity(
              opacity: _footerOpacity,
              child: Text(
                getElapsedTime(message.timestamp),
                style: const TextStyle(fontSize: _footerFontSize),
              ),
            ),
          ],
        ),

        // Right side: copy and view details
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: _footerIconSpacing,
          children: <Widget>[
            IconButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: message.message));
              },
              icon: const Icon(Icons.copy, size: _footerIconSize),
              padding: const EdgeInsets.all(_footerIconPadding),
              constraints: const BoxConstraints(),
              tooltip: 'Copy message to clipboard',
            ),
            IconButton(
              onPressed: onViewDetails,
              icon: Icon(
                isUser ? Icons.comment : Icons.info,
                size: _footerIconSize,
              ),
              padding: const EdgeInsets.all(_footerIconPadding),
              constraints: const BoxConstraints(),
              tooltip: isUser ? 'View prompt details' : 'View message details',
            ),
          ],
        ),
      ],
    );
  }
}
