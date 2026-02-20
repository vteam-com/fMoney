enum ChatFrom { user, ai }

/// Represents chat message.
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

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'message': message,
      'type': type.name, // Convert enum to string
      'timestamp': timestamp.toIso8601String(), // Convert DateTime to ISO string
      'payloadSentToOllama': payloadSentToOllama,
      'isExpanded': isExpanded,
    };
  }

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
    );
  }
}
