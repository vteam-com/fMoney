import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:money/data/storage/data/data.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/views/home/sub_views/view_ai/ollama_service.dart';
import 'package:money/widgets/box.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/my_svg.dart';
import 'package:money/widgets/text_title.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewAIInstructions extends StatelessWidget {
  const ViewAIInstructions({
    super.key,
    this.isOllamaInstalled = false,
    this.isOllamaRunning = false,
    this.onCheckStatus,
    this.onInstall,
  });

  final bool isOllamaInstalled;
  final bool isOllamaRunning;
  final VoidCallback? onCheckStatus;
  final VoidCallback? onInstall;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Box(
        padding: SizeForPadding.large,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MySvg(
              assetName: 'ollama.svg',
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            gapLarge(),
            const TextTitle('Ollama AI Assistant'),
            gapMedium(),
            const Text(
              'Ollama is required to use the AI assistant. Click below to install it.',
              textAlign: TextAlign.center,
            ),
            gapLarge(),
            if (!isOllamaInstalled)
              ElevatedButton(
                onPressed: onInstall,
                child: const Text('Install Ollama now'),
              ),
            if (!isOllamaRunning)
              ElevatedButton(
                onPressed: onCheckStatus,
                child: const Text('Run Ollama'),
              ),
          ],
        ),
      ),
    );
  }
}

class OllamaManager {
  static bool _isOllamaInstalled = false;
  static bool _isOllamaRunning = false;
  static final List<Map<String, dynamic>> _availableModels = <Map<String, dynamic>>[];
  // Selected model is now managed in OllamaService

  static bool get isOllamaInstalled => _isOllamaInstalled;
  static bool get isOllamaRunning => _isOllamaRunning;
  static List<Map<String, dynamic>> get availableModels => _availableModels;
  // Selected model is now managed in OllamaService

  static Future<void> checkOllamaStatus() async {
    _isOllamaInstalled = false;
    _isOllamaRunning = false;

    try {
      // First check if Ollama is installed using shell command
      _isOllamaInstalled = await _checkIfOllamaInstalled();

      if (_isOllamaInstalled) {
        _isOllamaRunning = await _checkIfOllamaRunning();
        if (!_isOllamaRunning) {
          await _startOllama();
          _isOllamaRunning = await _checkIfOllamaRunning();
        }

        // Get the list of models
        if (_isOllamaRunning) {
          await _loadAvailableModels();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ollama check error: $e');
      }
    }
  }

  static Future<bool> _checkIfOllamaInstalled() async {
    try {
      // First check if Ollama is installed using shell command
      final ProcessResult installResult = await Process.run('which', <String>['ollama']);

      return installResult.exitCode == 0;
    } catch (e) {
      _isOllamaInstalled = false;
      if (kDebugMode) {
        print('Ollama check error: $e');
      }
    }
    return false;
  }

  static Future<bool> _checkIfOllamaRunning() async {
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

  // Launch the macOS Ollama app directly (same as clicking it in Applications)
  static Future<void> _startOllama() async {
    try {
      // Check if Ollama is already running
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
        // 🧩 Launch Ollama as a background process, *without showing its window*
        await Process.start(
          'ollama',
          <String>['run', OllamaService.selectedModel],
          mode: ProcessStartMode.detached,
          environment: Platform.environment,
        );
        debugPrint('Launching Ollama silently on macOS...');
      } else if (Platform.isWindows) {
        // 🧩 Launch Ollama in the background (no console window)
        await Process.start(
          'cmd',
          <String>['/c', 'start', '/min', 'ollama', 'serve'],
          mode: ProcessStartMode.detached,
        );
        debugPrint('Launching Ollama silently on Windows...');
      } else if (Platform.isLinux) {
        // 🧩 Linux typically only has the CLI
        await Process.start(
          'ollama',
          <String>['serve'],
          mode: ProcessStartMode.detached,
        );
        debugPrint('Launching Ollama silently on Linux...');
      } else {
        throw UnsupportedError('Unsupported platform');
      }

      // Give Ollama a few seconds to boot up
      await Future<dynamic>.delayed(const Duration(seconds: 5));

      // Verify Ollama API is ready
      final HttpClient verifyClient = HttpClient();
      final HttpClientRequest verifyRequest = await verifyClient.getUrl(Uri.parse('http://localhost:11434/api/tags'));
      final HttpClientResponse verifyResponse = await verifyRequest.close();
      if (verifyResponse.statusCode == 200) {
        debugPrint('✅ Ollama started and responding.');
      } else {
        debugPrint('⚠️ Ollama started but not responding correctly.');
      }
      verifyClient.close();
    } catch (e) {
      debugPrint('❌ Failed to start Ollama: $e');
    }
  }

  static Future<void> _loadAvailableModels() async {
    try {
      final HttpClient client = HttpClient();
      final HttpClientRequest request = await client.getUrl(Uri.parse('http://localhost:11434/api/tags'));
      final HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        final String responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
        final List<dynamic> models = jsonResponse['models'] as List<dynamic>;
        _availableModels.clear();
        _availableModels.addAll(
          models.map((final dynamic model) => model as Map<String, dynamic>),
        );
        // Sort models by name
        _availableModels.sort(
          (final Map<String, dynamic> a, final Map<String, dynamic> b) =>
              stringCompareIgnoreCasing2(a['name'] as String, b['name'] as String),
        );
        OllamaService.selectedModel = models.isNotEmpty ? models.first['name'] as String : OllamaService.selectedModel;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading models: $e');
      }
    }
  }

  static Future<void> loadSelectedModel() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    OllamaService.selectedModel = prefs.getString('selected_ollama_model') ?? OllamaService.selectedModel;
  }

  static Future<void> saveSelectedModel(final String model) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_ollama_model', model);
    OllamaService.selectedModel = model;
  }
}
