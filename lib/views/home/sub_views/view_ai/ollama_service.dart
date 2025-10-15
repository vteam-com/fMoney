import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

// Using a const for now, but this should be configurable and loaded dynamically
String modelToUseInOllama = 'martain7r/finance-llama-8b:q4_k_m'; //'gpt-oss:20b',

class OllamaService {
  static Future<bool> checkIfOllamaInstalled() async {
    try {
      final ProcessResult installResult = await Process.run('which', <String>['ollama']);
      return installResult.exitCode == 0;
    } catch (e) {
      if (kDebugMode) {
        print('Ollama check error: $e');
      }
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
          <String>['run', modelToUseInOllama],
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
}
