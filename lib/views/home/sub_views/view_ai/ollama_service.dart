import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:money/core/helpers/list_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class OllamaService {
  static final List<Map<String, dynamic>> availableModels = <Map<String, dynamic>>[];
  static String selectedModel = '';
  static Future<bool> checkIfOllamaInstalled() async {
    try {
      final ProcessResult installResult = await Process.run('which', <String>['ollama']);
      return installResult.exitCode == 0;
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

      return (response.statusCode == 200);
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
        if (response.statusCode == 200) {
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

      await Future<dynamic>.delayed(const Duration(seconds: 5));

      final HttpClient verifyClient = HttpClient();
      final HttpClientRequest verifyRequest = await verifyClient.getUrl(Uri.parse('http://localhost:11434/api/tags'));
      final HttpClientResponse verifyResponse = await verifyRequest.close();

      if (verifyResponse.statusCode == 200) {
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
      if (response.statusCode == 200) {
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
}
