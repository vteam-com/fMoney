import 'package:flutter_test/flutter_test.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai_chat_types.dart';

void main() {
  final DateTime testDateTime = DateTime(2023, 12, 15, 10, 30, 45);

  group('ChatMessage Serialization', () {
    test('serializes user message correctly', () {
      final ChatMessage message = ChatMessage(
        message: 'Hello AI',
        type: ChatFrom.user,
        timestamp: testDateTime,
        payloadSentToOllama: <String, dynamic>{
          'model': 'test-model',
          'context': <int>[1, 2, 3],
        },
        isExpanded: true,
      );

      final Map<String, dynamic> json = message.toJson();

      expect(json['message'], 'Hello AI');
      expect(json['type'], 'user');
      expect(json['timestamp'], '2023-12-15T10:30:45.000');
      expect(json['isExpanded'], true);
      expect(json['payloadSentToOllama'], <String, dynamic>{
        'model': 'test-model',
        'context': <int>[1, 2, 3],
      });
    });

    test('serializes AI message correctly', () {
      final ChatMessage message = ChatMessage(
        message: 'Hello User',
        type: ChatFrom.ai,
        timestamp: testDateTime,
        payloadSentToOllama: <String, dynamic>{},
        isExpanded: false,
      );

      final Map<String, dynamic> json = message.toJson();

      expect(json['message'], 'Hello User');
      expect(json['type'], 'ai');
      expect(json['timestamp'], '2023-12-15T10:30:45.000');
      expect(json['isExpanded'], false);
      expect(json['payloadSentToOllama'], <String, dynamic>{});
    });

    test('serializes message with special characters', () {
      final ChatMessage message = ChatMessage(
        message: 'Hello "world" with & special <chars>',
        type: ChatFrom.user,
        timestamp: testDateTime,
        payloadSentToOllama: <String, dynamic>{},
        isExpanded: false,
      );

      final Map<String, dynamic> json = message.toJson();
      final ChatMessage deserialized = ChatMessage.fromJson(json);

      expect(deserialized.message, 'Hello "world" with & special <chars>');
      expect(deserialized.type, ChatFrom.user);
      expect(deserialized.timestamp, testDateTime);
    });
  });

  group('ChatMessage Deserialization', () {
    test('deserializes user message correctly', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'message': 'Test message',
        'type': 'user',
        'timestamp': '2023-12-15T10:30:45.000',
        'payloadSentToOllama': <String, dynamic>{'model': 'test-model'},
        'isExpanded': true,
      };

      final ChatMessage message = ChatMessage.fromJson(json);

      expect(message.message, 'Test message');
      expect(message.type, ChatFrom.user);
      expect(message.timestamp, testDateTime);
      expect(message.payloadSentToOllama, <String, dynamic>{'model': 'test-model'});
      expect(message.isExpanded, true);
    });

    test('deserializes AI message correctly', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'message': 'AI response',
        'type': 'ai',
        'timestamp': '2023-12-15T10:30:45.000',
        'payloadSentToOllama': <String, dynamic>{},
        'isExpanded': false,
      };

      final ChatMessage message = ChatMessage.fromJson(json);

      expect(message.message, 'AI response');
      expect(message.type, ChatFrom.ai);
      expect(message.timestamp, testDateTime);
      expect(message.payloadSentToOllama, <String, dynamic>{});
      expect(message.isExpanded, false);
    });

    test('handles empty payload gracefully', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'message': 'Test',
        'type': 'user',
        'timestamp': '2023-12-15T10:30:45.000',
        'payloadSentToOllama': null,
        'isExpanded': null,
      };

      final ChatMessage message = ChatMessage.fromJson(json);

      expect(message.message, 'Test');
      expect(message.type, ChatFrom.user);
      expect(message.payloadSentToOllama, <String, dynamic>{});
      expect(message.isExpanded, false);
    });

    test('handles invalid enum value gracefully', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'message': 'Test',
        'type': 'invalid_type',
        'timestamp': '2023-12-15T10:30:45.000',
        'payloadSentToOllama': <String, dynamic>{},
        'isExpanded': false,
      };

      final ChatMessage message = ChatMessage.fromJson(json);

      expect(message.type, ChatFrom.ai); // fallback to ai
    });
  });

  group('ChatMessage Roundtrip', () {
    test('can serialize and deserialize without data loss', () {
      final ChatMessage original = ChatMessage(
        message: 'Complex message with "quotes" & special chars',
        type: ChatFrom.ai,
        timestamp: testDateTime,
        payloadSentToOllama: <String, dynamic>{
          'model': 'llama3.2:3b',
          'context': <int>[10, 20, 30, 40, 50],
        },
        isExpanded: true,
      );

      // Serialize
      final Map<String, dynamic> json = original.toJson();

      // Deserialize
      final ChatMessage restored = ChatMessage.fromJson(json);

      // Verify all properties are preserved
      expect(restored.message, original.message);
      expect(restored.type, original.type);
      expect(restored.timestamp, original.timestamp);
      expect(restored.payloadSentToOllama, original.payloadSentToOllama);
      expect(restored.isExpanded, original.isExpanded);
    });

    test('handles DateTime with milliseconds correctly', () {
      final DateTime preciseTime = DateTime(2023, 1, 15, 10, 30, 45, 500);
      final ChatMessage original = ChatMessage(
        message: 'Message',
        type: ChatFrom.user,
        timestamp: preciseTime,
        payloadSentToOllama: <String, dynamic>{},
        isExpanded: false,
      );

      final Map<String, dynamic> json = original.toJson();
      final ChatMessage restored = ChatMessage.fromJson(json);

      expect(restored.timestamp, preciseTime);
    });
  });
}
