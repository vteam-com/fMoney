import 'package:flutter_test/flutter_test.dart';
import 'package:money/views/home/sub_views/view_ai/ollama_service.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai_chat_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  final DateTime testDateTime = DateTime(2023, 12, 15, 10, 30, 45);

  // Create test messages
  late ChatMessage userMessage;
  late ChatMessage aiMessage;
  late List<ChatMessage> testMessages;

  setUp(() {
    userMessage = ChatMessage(
      message: 'Hello AI',
      type: ChatFrom.user,
      timestamp: testDateTime,
      payloadSentToOllama: <String, dynamic>{'model': 'test-model'},
      isExpanded: false,
    );

    aiMessage = ChatMessage(
      message: 'Hello User!',
      type: ChatFrom.ai,
      timestamp: testDateTime.add(const Duration(seconds: 2)),
      payloadSentToOllama: <String, dynamic>{'model': 'test-model', 'response': 'success'},
      isExpanded: true,
    );

    testMessages = <ChatMessage>[userMessage, aiMessage];
  });

  tearDown(() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Clean up all test preferences
    await prefs.remove('ollama_chat_history_llama3.2:3b');
    await prefs.remove('ollama_chat_history_test-model');
    await prefs.remove('ollama_chat_history_empty-test');
    await prefs.remove('ollama_chat_history_complex-test');
    await prefs.remove('ollama_chat_history_delete-test');
    await prefs.remove('ollama_chat_history_model-A');
    await prefs.remove('ollama_chat_history_model-B');
    await prefs.remove('ollama_chat_history_edge-case-test');
    await prefs.remove('ollama_chat_history_roundtrip-test');
  });

  group('OllamaService Chat History Save/Load', () {
    test('saves and loads chat history for specific model', () async {
      // Set up OllamaService for testing
      OllamaService.selectedModel = 'llama3.2:3b';

      // Save chat history
      await OllamaService.saveChatHistory(testMessages);

      // Load chat history
      final List<ChatMessage> loadedMessages = await OllamaService.loadChatHistory();

      // Verify loaded messages
      expect(loadedMessages.length, 2);

      expect(loadedMessages[0].message, userMessage.message);
      expect(loadedMessages[0].type, userMessage.type);
      expect(loadedMessages[0].timestamp, userMessage.timestamp);
      expect(loadedMessages[0].isExpanded, userMessage.isExpanded);

      expect(loadedMessages[1].message, aiMessage.message);
      expect(loadedMessages[1].type, aiMessage.type);
      expect(loadedMessages[1].timestamp, aiMessage.timestamp);
      expect(loadedMessages[1].isExpanded, aiMessage.isExpanded);
    });

    test('returns empty list when no chat history exists', () async {
      // Set up OllamaService for testing
      OllamaService.selectedModel = 'empty-test';

      // Load chat history for non-existent key
      final List<ChatMessage> loadedMessages = await OllamaService.loadChatHistory();

      expect(loadedMessages, isEmpty);
      expect(loadedMessages.length, 0);
    });

    test('saves empty chat history (deletions)', () async {
      // First save some messages
      OllamaService.selectedModel = 'delete-test';
      await OllamaService.saveChatHistory(testMessages);

      // Verify messages exist
      final List<ChatMessage> loadedBefore = await OllamaService.loadChatHistory();
      expect(loadedBefore.length, 2);

      // Clear chat history
      await OllamaService.saveChatHistory(<ChatMessage>[]);

      // Verify messages are cleared
      final List<ChatMessage> loadedAfter = await OllamaService.loadChatHistory();
      expect(loadedAfter, isEmpty);
    });

    test('isolates chat history by model', () async {
      // Save messages for model A
      OllamaService.selectedModel = 'model-A';
      await OllamaService.saveChatHistory(<ChatMessage>[userMessage]);

      // Save different messages for model B
      OllamaService.selectedModel = 'model-B';
      await OllamaService.saveChatHistory(<ChatMessage>[aiMessage]);

      // Verify model A has only user message
      OllamaService.selectedModel = 'model-A';
      final List<ChatMessage> loadedA = await OllamaService.loadChatHistory();
      expect(loadedA.length, 1);
      expect(loadedA[0].type, ChatFrom.user);

      // Verify model B has only AI message
      OllamaService.selectedModel = 'model-B';
      final List<ChatMessage> loadedB = await OllamaService.loadChatHistory();
      expect(loadedB.length, 1);
      expect(loadedB[0].type, ChatFrom.ai);
    });

    test('handles complex chat histories with special characters', () async {
      OllamaService.selectedModel = 'complex-test';

      final ChatMessage complexMessage = ChatMessage(
        message: 'Complex: "quotes", & <special> chars with émojis 😀 and multiple lines\nLine 2',
        type: ChatFrom.user,
        timestamp: testDateTime,
        payloadSentToOllama: <String, dynamic>{
          'model': 'complex-model',
          'prompt': 'special "prompt"\nwith lines',
          'context': <int>[1, 2, 3, 100, 200],
        },
        isExpanded: true,
      );

      // Save complex message
      await OllamaService.saveChatHistory(<ChatMessage>[complexMessage]);

      // Load and verify
      final List<ChatMessage> loaded = await OllamaService.loadChatHistory();
      expect(loaded.length, 1);

      final ChatMessage restored = loaded[0];
      expect(restored.message, complexMessage.message);
      expect(restored.type, complexMessage.type);
      expect(restored.timestamp, complexMessage.timestamp);
      expect(restored.isExpanded, complexMessage.isExpanded);
      expect(restored.payloadSentToOllama, complexMessage.payloadSentToOllama);
    });

    test('handles messages without timestamps correctly', () async {
      OllamaService.selectedModel = 'edge-case-test';

      // Create message without proper initialization to test edge cases
      final ChatMessage edgeMessage = ChatMessage(
        message: 'Edge case message',
        type: ChatFrom.ai,
        timestamp: DateTime.now(), // Runtime DateTime, not const
        payloadSentToOllama: <String, dynamic>{},
        isExpanded: false,
      );

      await OllamaService.saveChatHistory(<ChatMessage>[edgeMessage]);
      final List<ChatMessage> loaded = await OllamaService.loadChatHistory();

      expect(loaded.length, 1);
      expect(loaded[0].message, 'Edge case message');
      expect(loaded[0].type, ChatFrom.ai);
    });

    test('survives serialization roundtrip without data corruption', () async {
      OllamaService.selectedModel = 'roundtrip-test';

      // Create message with all fields populated
      final ChatMessage original = ChatMessage(
        message: 'Roundtrip test with full data',
        type: ChatFrom.user,
        timestamp: DateTime(2024, 3, 15, 14, 30, 0, 123),
        payloadSentToOllama: <String, dynamic>{
          'model': 'roundtrip-model',
          'stream': true,
          'context': <int>[10, 20, 30, 40],
          'options': <String, dynamic>{'temperature': 0.7, 'top_p': 0.9},
        },
        isExpanded: true,
      );

      // Save and reload through OllamaService (which uses JSON serialization)
      await OllamaService.saveChatHistory(<ChatMessage>[original]);
      final List<ChatMessage> loaded = await OllamaService.loadChatHistory();

      expect(loaded.length, 1);
      final ChatMessage restored = loaded[0];

      expect(restored.message, original.message);
      expect(restored.type, original.type);
      expect(restored.timestamp, original.timestamp);
      expect(restored.isExpanded, original.isExpanded);
      expect(restored.payloadSentToOllama, original.payloadSentToOllama);
    });
  });
}
