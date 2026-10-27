// ignore: fcheck_one_class_per_file
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:money/data/models/ai_chat_model.dart';
import 'package:money/helpers/app_logger_helper.dart';
import 'package:money/helpers/list_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const int _exitCodeSuccess = 0;
const int _httpOkStatus = 200;
const int _startupDelaySeconds = 5;
const String _defaultPathEnvKey = 'PATH';
const String _windowsPathEnvKey = 'Path';
const String _windowsProgramsDirName = 'Programs';
const String _windowsOllamaDirName = 'Ollama';
const String _windowsOllamaExecutableName = 'ollama.exe';

const List<String> _commonMacOsPaths = <String>[
  '/opt/homebrew/bin',
  '/usr/local/bin',
  '/Applications/Ollama.app/Contents/Resources',
];

const List<String> _commonLinuxPaths = <String>[
  '/usr/local/bin',
  '/usr/bin',
  '/snap/bin',
];

const List<String> _commonWindowsPaths = <String>[
  r'C:\Program Files\Ollama',
  r'C:\Program Files (x86)\Ollama',
];

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

  /// Returns true if the `ollama` executable is available on the system.
  static Future<bool> checkIfOllamaInstalled() async {
    try {
      final String? ollamaExecutablePath = await _resolveOllamaExecutablePath();
      return ollamaExecutablePath != null;
    } catch (e) {
      AppLogger.warning(
        module: 'ollama_service',
        operation: 'checkIfOllamaInstalled',
        message: e.toString(),
      );
      return false;
    }
  }

  /// Returns true if the local Ollama HTTP API is responding.
  static Future<bool> checkIfOllamaRunning() async {
    try {
      final Uri ollamaUrl = Uri.parse('http://localhost:11434/api/tags');
      final HttpClient client = HttpClient();
      final HttpClientResponse response = await client
          .getUrl(ollamaUrl)
          .then((HttpClientRequest request) => request.close());

      return (response.statusCode == _httpOkStatus);
    } catch (e) {
      AppLogger.warning(
        module: 'ollama_service',
        operation: 'checkIfOllamaRunning',
        message: e.toString(),
      );
      return false;
    }
  }

  /// Opens the Ollama download page in the browser.
  static Future<void> installOllama() async {
    // Open Ollama download page
    final Uri url = Uri.parse('https://ollama.com/download');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  /// Starts the Ollama service in the background if it is not already running.
  static Future<void> startOllama() async {
    try {
      final HttpClient client = HttpClient();
      try {
        final HttpClientRequest request = await client.getUrl(Uri.parse('http://localhost:11434/api/tags'));
        final HttpClientResponse response = await request.close();
        if (response.statusCode == _httpOkStatus) {
          return;
        }
      } catch (_) {
        // Not running, we'll launch it
      } finally {
        client.close();
      }

      final String? ollamaExecutablePath = await _resolveOllamaExecutablePath();
      if (ollamaExecutablePath == null) {
        AppLogger.warning(
          module: 'ollama_service',
          operation: 'startOllama',
          message: 'Ollama executable was not found on this machine',
        );
        return;
      }

      final Map<String, String> processEnvironment = _buildProcessEnvironment();

      if (Platform.isMacOS) {
        await Process.start(
          ollamaExecutablePath,
          <String>[SharedStrings.ollamaArgServe],
          mode: ProcessStartMode.detached,
          environment: processEnvironment,
        );
      } else if (Platform.isWindows) {
        await Process.start(
          ollamaExecutablePath,
          <String>[SharedStrings.ollamaArgServe],
          mode: ProcessStartMode.detached,
          environment: processEnvironment,
        );
      } else if (Platform.isLinux) {
        await Process.start(
          ollamaExecutablePath,
          <String>[SharedStrings.ollamaArgServe],
          mode: ProcessStartMode.detached,
          environment: processEnvironment,
        );
      } else {
        throw UnsupportedError('Unsupported platform');
      }

      await Future<dynamic>.delayed(const Duration(seconds: _startupDelaySeconds));

      final HttpClient verifyClient = HttpClient();
      final HttpClientRequest verifyRequest = await verifyClient.getUrl(Uri.parse('http://localhost:11434/api/tags'));
      final HttpClientResponse verifyResponse = await verifyRequest.close();

      if (verifyResponse.statusCode != _httpOkStatus) {
        AppLogger.warning(
          module: 'ollama_service',
          operation: 'startOllama',
          message: 'Ollama started but not responding correctly',
        );
      }

      verifyClient.close();
    } catch (e) {
      AppLogger.error(
        module: 'ollama_service',
        operation: 'startOllama',
        error: e,
      );
    }
  }

  /// Loads the list of available models from the local Ollama API.
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
          models.map((dynamic model) => model as Map<String, dynamic>),
        );
        // Sort models by name
        availableModels.sort(
          (Map<String, dynamic> a, Map<String, dynamic> b) =>
              sortByString(a['name'] as String, b['name'] as String, true),
        );

        // Verify that the selected model is still available, otherwise use the first one
        if (selectedModel.isNotEmpty &&
            !availableModels.any((Map<String, dynamic> model) => model['name'] == selectedModel)) {
          // User's selected model is no longer available, reset to first available
          selectedModel = models.isNotEmpty ? models.first['name'] as String : '';
        } else if (selectedModel.isEmpty && models.isNotEmpty) {
          // No model selected yet, use the first available
          selectedModel = models.first['name'] as String;
        }

        return availableModels;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        module: 'ollama_service',
        operation: 'loadAvailableModels',
        error: e,
        stackTrace: stackTrace,
      );
    }
    return <Map<String, dynamic>>[];
  }

  /// Loads the last user-selected model from preferences.
  static Future<void> getLastUserSelectedModel() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String loadedModel = prefs.getString('selected_ollama_model') ?? selectedModel;
    selectedModel = loadedModel;
  }

  /// Persists the selected model to preferences.
  static Future<void> saveSelectedModel(String model) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_ollama_model', model);
  }

  /// Persists the conversation context token list for the current model.
  static Future<void> saveConversationContext(List<int>? context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (context != null) {
      await prefs.setString('ollama_context_$selectedModel', jsonEncode(context));
    } else {
      await prefs.remove('ollama_context_$selectedModel');
    }
  }

  /// Loads the conversation context token list for the current model.
  static Future<List<int>?> loadConversationContext() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? contextString = prefs.getString('ollama_context_$selectedModel');
    if (contextString != null) {
      final List<dynamic> contextList = jsonDecode(contextString) as List<dynamic>;
      return contextList.cast<int>();
    }
    return null;
  }

  /// Persists chat history for the current model.
  static Future<void> saveChatHistory(List<ChatMessage> chatHistory) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (chatHistory.isNotEmpty) {
      final List<Map<String, dynamic>> serializedHistory = chatHistory.map((ChatMessage msg) => msg.toJson()).toList();
      await prefs.setString('ollama_chat_history_$selectedModel', jsonEncode(serializedHistory));
    } else {
      await prefs.remove('ollama_chat_history_$selectedModel');
    }
  }

  /// Loads chat history for the current model.
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

  /// Sends a payload to the local Ollama API and returns the decoded JSON response.
  static Future<Map<String, dynamic>> sendPayload(Map<String, dynamic> payload) async {
    const String endpoint = 'generate'; // Use /api/generate for context support instead of /api/chat
    final Uri generateUrl = Uri.parse('http://localhost:11434/api/$endpoint');
    final HttpClient client = HttpClient();
    final HttpClientRequest request = await client.postUrl(generateUrl);
    request.headers.contentType = ContentType.json;

    // Convert messages format if needed for /api/generate
    if (endpoint == 'generate' && payload.containsKey(SharedStrings.payloadKeyMessages)) {
      final List<Map<String, String>> messages = payload[SharedStrings.payloadKeyMessages] as List<Map<String, String>>;
      // Combine messages into a single prompt for /api/generate
      final StringBuffer prompt = StringBuffer();
      for (final Map<String, String> message in messages) {
        final String role = message['role'] ?? '';
        final String content = message['content'] ?? '';
        if (role == 'system') {
          prompt.write(SharedStrings.promptPrefixSystem + content + SharedStrings.lineFeed + SharedStrings.lineFeed);
        } else if (role == 'user') {
          prompt.write(SharedStrings.promptPrefixUser + content + SharedStrings.lineFeed + SharedStrings.lineFeed);
        } else if (role == 'assistant') {
          prompt.write(SharedStrings.promptPrefixAssistant + content + SharedStrings.lineFeed + SharedStrings.lineFeed);
        }
      }

      // Create new payload for /api/generate
      final Map<String, dynamic> generatePayload = <String, dynamic>{
        'model': payload['model'],
        'prompt': prompt.toString(),
        'stream': false,
      };

      // Add context if present
      if (payload.containsKey(SharedStrings.payloadKeyContext)) {
        generatePayload[SharedStrings.payloadKeyContext] = payload[SharedStrings.payloadKeyContext];
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

  /// Checks if Ollama is installed/running and loads models if available.
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

  /// Resolves the full executable path for Ollama across supported platforms.
  static Future<String?> _resolveOllamaExecutablePath() async {
    final Map<String, String> environment = _buildProcessEnvironment();

    final String? fromLocator = await _resolveUsingSystemLocator(environment);
    if (fromLocator != null) {
      return fromLocator;
    }

    final String? fromPath = await _resolveUsingPathEntries(environment);
    if (fromPath != null) {
      return fromPath;
    }

    final String? fromCommonLocations = await _resolveFromCommonLocations();
    if (fromCommonLocations != null) {
      return fromCommonLocations;
    }

    return null;
  }

  /// Builds a process environment with augmented path entries for desktop app launches.
  static Map<String, String> _buildProcessEnvironment() {
    final Map<String, String> environment = Map<String, String>.from(Platform.environment);
    final String pathKey = _resolvePathEnvironmentKey(environment);
    final String currentPath = environment[pathKey] ?? SharedStrings.empty;
    final String separator = Platform.isWindows ? ';' : ':';
    final Set<String> pathEntries = currentPath
        .split(separator)
        .where((String entry) => entry.trim().isNotEmpty)
        .toSet();

    final Iterable<String> fallbackEntries = _platformFallbackPathEntries(environment);
    pathEntries.addAll(fallbackEntries.where((String entry) => entry.trim().isNotEmpty));
    environment[pathKey] = pathEntries.join(separator);
    return environment;
  }

  /// Resolves which environment variable key stores PATH on the current platform.
  static String _resolvePathEnvironmentKey(Map<String, String> environment) {
    if (Platform.isWindows) {
      if (environment.containsKey(_windowsPathEnvKey)) {
        return _windowsPathEnvKey;
      }
      for (final String key in environment.keys) {
        if (key.toLowerCase() == _defaultPathEnvKey.toLowerCase()) {
          return key;
        }
      }
    }
    return _defaultPathEnvKey;
  }

  /// Returns platform-specific fallback path entries used when PATH is minimal.
  static Iterable<String> _platformFallbackPathEntries(Map<String, String> environment) {
    if (Platform.isMacOS) {
      return _commonMacOsPaths;
    }
    if (Platform.isLinux) {
      return _commonLinuxPaths;
    }
    if (Platform.isWindows) {
      final String localAppData = environment['LOCALAPPDATA'] ?? SharedStrings.empty;
      final List<String> entries = <String>[..._commonWindowsPaths];
      if (localAppData.isNotEmpty) {
        entries.add(
          '$localAppData${Platform.pathSeparator}$_windowsProgramsDirName${Platform.pathSeparator}$_windowsOllamaDirName',
        );
      }
      return entries;
    }
    return <String>[];
  }

  /// Tries to resolve Ollama using the platform command locator (`which` or `where`).
  static Future<String?> _resolveUsingSystemLocator(Map<String, String> environment) async {
    final String locatorCommand = Platform.isWindows ? 'where' : SharedStrings.processWhich;
    try {
      final ProcessResult installResult = await Process.run(
        locatorCommand,
        <String>[SharedStrings.executableOllama],
        environment: environment,
      );
      if (installResult.exitCode != _exitCodeSuccess) {
        return null;
      }
      final String output = (installResult.stdout as Object? ?? SharedStrings.empty).toString().trim();
      if (output.isEmpty) {
        return null;
      }
      final List<String> candidates = output
          .split(RegExp(r'[\r\n]+'))
          .map((String line) => line.trim())
          .where((String line) => line.isNotEmpty)
          .toList();
      return await _firstExistingPath(candidates);
    } catch (_) {
      return null;
    }
  }

  /// Tries to resolve Ollama by walking all PATH entries directly.
  static Future<String?> _resolveUsingPathEntries(Map<String, String> environment) async {
    final String pathKey = _resolvePathEnvironmentKey(environment);
    final String pathValue = environment[pathKey] ?? SharedStrings.empty;
    if (pathValue.isEmpty) {
      return null;
    }
    final String separator = Platform.isWindows ? ';' : ':';
    final List<String> executableNames = Platform.isWindows
        ? <String>[_windowsOllamaExecutableName, 'ollama.cmd', 'ollama.bat', SharedStrings.executableOllama]
        : <String>[SharedStrings.executableOllama];

    final List<String> candidates = <String>[];
    for (final String entry in pathValue.split(separator)) {
      final String trimmedEntry = entry.trim();
      if (trimmedEntry.isEmpty) {
        continue;
      }
      for (final String executableName in executableNames) {
        candidates.add('$trimmedEntry${Platform.pathSeparator}$executableName');
      }
    }
    return _firstExistingPath(candidates);
  }

  /// Tries to resolve Ollama from common installation directories for each OS.
  static Future<String?> _resolveFromCommonLocations() async {
    final List<String> candidates = <String>[];
    if (Platform.isMacOS || Platform.isLinux) {
      final List<String> roots = Platform.isMacOS ? _commonMacOsPaths : _commonLinuxPaths;
      for (final String root in roots) {
        candidates.add('$root${Platform.pathSeparator}${SharedStrings.executableOllama}');
      }
    } else if (Platform.isWindows) {
      for (final String root in _commonWindowsPaths) {
        candidates.add('$root${Platform.pathSeparator}$_windowsOllamaExecutableName');
      }
      final String localAppData = Platform.environment['LOCALAPPDATA'] ?? SharedStrings.empty;
      if (localAppData.isNotEmpty) {
        candidates.add(
          '$localAppData${Platform.pathSeparator}$_windowsProgramsDirName${Platform.pathSeparator}$_windowsOllamaDirName${Platform.pathSeparator}$_windowsOllamaExecutableName',
        );
      }
    }
    return _firstExistingPath(candidates);
  }

  /// Returns the first candidate path that exists as a file.
  static Future<String?> _firstExistingPath(Iterable<String> candidates) async {
    for (final String candidate in candidates) {
      if (candidate.isEmpty) {
        continue;
      }
      final String normalizedCandidate = candidate.trim().replaceAll('"', SharedStrings.empty);
      if (normalizedCandidate.isEmpty) {
        continue;
      }
      final File file = File(normalizedCandidate);
      if (await file.exists()) {
        return file.path;
      }
    }
    return null;
  }
}
