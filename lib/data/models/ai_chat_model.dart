import 'package:money/data/models/ai_chat_action_model.dart';

/// JSON key of [ChatMessage.actions].
const String _keyActions = 'actions';

enum ChatFrom { user, ai }

/// Represents chat message.
class ChatMessage {
  ChatMessage({
    required this.message,
    required this.type,
    required this.timestamp,
    required this.payloadSentToOllama,
    this.isExpanded = false,
    this.actions = const <AiChatAction>[],
  });

  /// Views the AI offers to open from this answer, shown as buttons under it.
  final List<AiChatAction> actions;

  final String message;
  final ChatFrom type;
  final DateTime timestamp;

  /// The full request sent to Ollama for this message, kept in memory only: it embeds the selected
  /// accounts' transactions, so saving it with every question made the stored history huge.
  final Map<String, dynamic> payloadSentToOllama;
  bool isExpanded;

  /// Serializes this message to JSON, leaving out [payloadSentToOllama].
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'message': message,
      'type': type.name, // Convert enum to string
      'timestamp': timestamp.toIso8601String(), // Convert DateTime to ISO string
      'isExpanded': isExpanded,
      if (actions.isNotEmpty) _keyActions: actions.map((AiChatAction action) => action.toJson()).toList(),
    };
  }

  /// Deserializes a message from JSON.
  static ChatMessage fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      message: json['message'] as String,
      type: ChatFrom.values.firstWhere(
        (ChatFrom e) => e.name == json['type'],
        orElse: () => ChatFrom.ai, // fallback
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      payloadSentToOllama: (json['payloadSentToOllama'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      isExpanded: (json['isExpanded'] as bool?) ?? false,
      actions: ((json[_keyActions] as List<dynamic>?) ?? <dynamic>[])
          .map((dynamic action) => AiChatAction.fromJson(action as Map<String, dynamic>))
          .toList(),
    );
  }
}
