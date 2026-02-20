// ignore: fcheck_one_class_per_file
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/views/view_ai/view_ai_chat_types.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const int _exitCodeSuccess = 0;
const int _httpOkStatus = 200;
const int _startupDelaySeconds = 5;

/// Represents ollama status.
class OllamaStatus {
  OllamaStatus({
    required this.isInstalled,
    required this.isRunning,
  });

  final bool isInstalled;
  final bool isRunning;
}

/// Represents ollama service.
class OllamaService {
  static final List<Map<String, dynamic>> availableModels = <Map<String, dynamic>>[];
  static String selectedModel = '';
  static Future<bool> checkIfOllamaInstalled() async {
    try {
      final ProcessResult installResult = await Process.run('which', <String>['ollama']);
      return installResult.exitCode == _exitCodeSuccess;
    } catch (e) {
      debugPrint('Ollama check error: $e');
      return false;
    }
  }

  static Future<bool> checkIfOllamaRunning() async {
    try {
      final Uri ollamaUrl = Uri.parse('http://localhost:11434/api/tags');
      final HttpClient client = HttpClient();
      final HttpClientResponse response = await client
          .getUrl(ollamaUrl)
          .then((HttpClientRequest request) => request.close());

      return (response.statusCode == _httpOkStatus);
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  static Future<void> installOllama() async {
    // Open Ollama download page
    final Uri url = Uri.parse('https://ollama.com/download');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  static Future<void> startOllama() async {
    try {
      final HttpClient client = HttpClient();
      try {
        final HttpClientRequest request = await client.getUrl(Uri.parse('http://localhost:11434/api/tags'));
        final HttpClientResponse response = await request.close();
        if (response.statusCode == _httpOkStatus) {
          debugPrint('Ollama is already running.');
          return;
        }
      } catch (_) {
        // Not running, we'll launch it
      } finally {
        client.close();
      }

      if (Platform.isMacOS) {
        await Process.start(
          'ollama',
          <String>['run', selectedModel],
          mode: ProcessStartMode.detached,
          environment: Platform.environment,
        );

        debugPrint('Launching Ollama silently on macOS...');
      } else if (Platform.isWindows) {
        await Process.start(
          'cmd',
          <String>['/c', 'start', '/min', 'ollama', 'serve'],
          mode: ProcessStartMode.detached,
        );
        debugPrint('Launching Ollama silently on Windows...');
      } else if (Platform.isLinux) {
        await Process.start(
          'ollama',
          <String>['serve'],
          mode: ProcessStartMode.detached,
        );
        debugPrint('Launching Ollama silently on Linux...');
      } else {
        throw UnsupportedError('Unsupported platform');
      }

      await Future<dynamic>.delayed(const Duration(seconds: _startupDelaySeconds));

      final HttpClient verifyClient = HttpClient();
      final HttpClientRequest verifyRequest = await verifyClient.getUrl(Uri.parse('http://localhost:11434/api/tags'));
      final HttpClientResponse verifyResponse = await verifyRequest.close();

      if (verifyResponse.statusCode == _httpOkStatus) {
        if (kDebugMode) {
          debugPrint('✅ Ollama started and responding.');
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Ollama started but not responding correctly.');
        }
      }

      verifyClient.close();
    } catch (e) {
      debugPrint('❌ Failed to start Ollama: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> loadAvailableModels() async {
    try {
      final HttpClient client = HttpClient();
      final HttpClientRequest request = await client.getUrl(Uri.parse('http://localhost:11434/api/tags'));
      final HttpClientResponse response = await request.close();
      if (response.statusCode == _httpOkStatus) {
        final String responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
        final List<dynamic> models = jsonResponse['models'] as List<dynamic>;
        availableModels.clear();
        availableModels.addAll(
          models.map((final dynamic model) => model as Map<String, dynamic>),
        );
        // Sort models by name
        availableModels.sort(
          (final Map<String, dynamic> a, final Map<String, dynamic> b) =>
              sortByString(a['name'] as String, b['name'] as String, true),
        );

        // Verify that the selected model is still available, otherwise use the first one
        if (selectedModel.isNotEmpty &&
            !availableModels.any((final Map<String, dynamic> model) => model['name'] == selectedModel)) {
          // User's selected model is no longer available, reset to first available
          selectedModel = models.isNotEmpty ? models.first['name'] as String : '';
        } else if (selectedModel.isEmpty && models.isNotEmpty) {
          // No model selected yet, use the first available
          selectedModel = models.first['name'] as String;
        }

        return availableModels;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading models: $e');
      }
    }
    return <Map<String, dynamic>>[];
  }

  static Future<void> getLastUserSelectedModel() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String loadedModel = prefs.getString('selected_ollama_model') ?? selectedModel;
    selectedModel = loadedModel;
  }

  static Future<void> saveSelectedModel(final String model) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_ollama_model', model);
  }

  static Future<void> saveConversationContext(final List<int>? context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (context != null) {
      await prefs.setString('ollama_context_$selectedModel', jsonEncode(context));
    } else {
      await prefs.remove('ollama_context_$selectedModel');
    }
  }

  static Future<List<int>?> loadConversationContext() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? contextString = prefs.getString('ollama_context_$selectedModel');
    if (contextString != null) {
      final List<dynamic> contextList = jsonDecode(contextString) as List<dynamic>;
      return contextList.cast<int>();
    }
    return null;
  }

  static Future<void> saveChatHistory(final List<ChatMessage> chatHistory) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (chatHistory.isNotEmpty) {
      final List<Map<String, dynamic>> serializedHistory = chatHistory.map((ChatMessage msg) => msg.toJson()).toList();
      await prefs.setString('ollama_chat_history_$selectedModel', jsonEncode(serializedHistory));
    } else {
      await prefs.remove('ollama_chat_history_$selectedModel');
    }
  }

  static Future<List<ChatMessage>> loadChatHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString('ollama_chat_history_$selectedModel');
    if (historyString != null) {
      final List<dynamic> historyList = jsonDecode(historyString) as List<dynamic>;
      final List<Map<String, dynamic>> historyMaps = historyList.cast<Map<String, dynamic>>();
      return historyMaps.map(ChatMessage.fromJson).toList();
    }
    return <ChatMessage>[];
  }

  static Future<Map<String, dynamic>> sendPayload(final Map<String, dynamic> payload) async {
    const String endpoint = 'generate'; // Use /api/generate for context support instead of /api/chat
    final Uri generateUrl = Uri.parse('http://localhost:11434/api/$endpoint');
    final HttpClient client = HttpClient();
    final HttpClientRequest request = await client.postUrl(generateUrl);
    request.headers.contentType = ContentType.json;

    // Convert messages format if needed for /api/generate
    if (endpoint == 'generate' && payload.containsKey('messages')) {
      final List<Map<String, String>> messages = payload['messages'] as List<Map<String, String>>;
      // Combine messages into a single prompt for /api/generate
      final StringBuffer prompt = StringBuffer();
      for (final Map<String, String> message in messages) {
        final String role = message['role'] ?? '';
        final String content = message['content'] ?? '';
        if (role == 'system') {
          prompt.write('System: $content\n\n');
        } else if (role == 'user') {
          prompt.write('User: $content\n\n');
        } else if (role == 'assistant') {
          prompt.write('Assistant: $content\n\n');
        }
      }

      // Create new payload for /api/generate
      final Map<String, dynamic> generatePayload = <String, dynamic>{
        'model': payload['model'],
        'prompt': prompt.toString(),
        'stream': false,
      };

      // Add context if present
      if (payload.containsKey('context')) {
        generatePayload['context'] = payload['context'];
      }

      final List<int> utf8Body = utf8.encode(jsonEncode(generatePayload));
      request.add(utf8Body);
    } else {
      final List<int> utf8Body = utf8.encode(jsonEncode(payload));
      request.add(utf8Body);
    }

    final HttpClientResponse response = await request.close();
    final String responseBody = await response.transform(utf8.decoder).join();
    if (response.statusCode == _httpOkStatus) {
      client.close();
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } else {
      client.close();
      throw Exception('HTTP ${response.statusCode}: $responseBody');
    }
  }

  static Future<OllamaStatus> checkOllamaStatus() async {
    final bool isInstalled = await checkIfOllamaInstalled();
    bool isRunning = false;

    if (isInstalled) {
      isRunning = await checkIfOllamaRunning();
      if (!isRunning) {
        await startOllama();
        isRunning = await checkIfOllamaRunning();
      }

      // Get the list of models if running
      if (isRunning) {
        await loadAvailableModels();
      }
    }

    return OllamaStatus(isInstalled: isInstalled, isRunning: isRunning);
  }
}
