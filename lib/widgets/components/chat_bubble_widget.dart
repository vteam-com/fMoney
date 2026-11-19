import 'package:material_ui/material_ui.dart';

const double _bubbleVerticalMargin = 4.0;
const double _bubblePadding = 12.0;
const double _bubbleRadius = 16.0;
const double _bubbleTailRadius = 3.0;

/// A rounded chat bubble whose bottom corner on the sender's side is drawn as a small tail.
class ChatBubble extends StatelessWidget {
  /// Creates a bubble filled with [color] around [child].
  const ChatBubble({
    required this.color,
    required this.isFromUser,
    required this.child,
    super.key,
  });

  /// Content shown inside the bubble.
  final Widget child;

  /// Fill color of the bubble.
  final Color color;

  /// Puts the tail on the bottom-right corner (user messages) instead of the bottom-left one.
  final bool isFromUser;

  /// Builds the padded, rounded bubble.
  @override
  Widget build(BuildContext context) {
    const Radius round = Radius.circular(_bubbleRadius);
    const Radius tail = Radius.circular(_bubbleTailRadius);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: _bubbleVerticalMargin),
      padding: const EdgeInsets.all(_bubblePadding),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: round,
          topRight: round,
          bottomLeft: isFromUser ? round : tail,
          bottomRight: isFromUser ? tail : round,
        ),
      ),
      child: child,
    );
  }
}
