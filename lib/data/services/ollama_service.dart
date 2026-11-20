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

/// How long to wait for the local Ollama server to accept a connection.
const Duration _connectionTimeout = Duration(seconds: 5);

/// How long a health check (listing models) may take in total.
const Duration _healthCheckTimeout = Duration(seconds: 10);

/// Preference key prefix of each model's saved chat history; the model name follows it.
const String _chatHistoryKeyPrefix = 'ollama_chat_history_';

/// Preference key prefix of the conversation tokens older versions saved per model and re-sent with
/// every question; no longer used.
const String _legacyConversationContextKeyPrefix = 'ollama_context_';

/// Characters per token assumed when sizing the context window, a little under the ~2.8 measured
/// on the account JSON prompts so the window errs on the large side.
const double _estimatedCharsPerToken = 2.5;

/// Tokens left free in the context window for the model's answer.
const int _answerTokenReserve = 4096;

/// Smallest context window (`num_ctx`) requested from Ollama.
const int _minContextTokens = 8192;

/// Largest context window (`num_ctx`) requested from Ollama. Larger windows can outgrow GPU memory
/// with 30B models, making Ollama run partly on the CPU and swap; Ollama truncates longer prompts.
const int _maxContextTokens = 65536;

/// Each larger context window step doubles the previous one (8K, 16K, 32K, 64K).
const int _contextWindowGrowthFactor = 2;

/// Ollama request option that sets the context window size in tokens.
const String _optionNumCtx = 'num_ctx';

/// Ollama request option that sets how freely the model picks its words.
const String _optionTemperature = 'temperature';

/// Temperature of tool conversations: low, so the model keeps to the tool-call format instead of
/// writing calls as plain text, and sticks to the data the tools return.
const double _toolChatTemperature = 0.1;

/// Key of a model's capability list in Ollama's model description.
const String _keyCapabilities = 'capabilities';

/// Capability Ollama lists for models that can call tools.
const String _capabilityTools = 'tools';
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

  /// Client of the [sendPayload] request in flight, so [cancelPayload] can abort it.
  static HttpClient? _payloadClient;

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
      return await _isServerResponding();
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
      try {
        if (await _isServerResponding()) {
          return;
        }
      } catch (_) {
        // Not running, we'll launch it
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

      if (!await _isServerResponding()) {
        AppLogger.warning(
          module: 'ollama_service',
          operation: 'startOllama',
          message: 'Ollama started but not responding correctly',
        );
      }
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
      final (int statusCode, String responseBody) = await _withClient(
        (HttpClient client) async {
          final HttpClientResponse response = await (await client.getUrl(_tagsUri)).close();
          return (response.statusCode, await response.transform(utf8.decoder).join());
        },
      ).timeout(_healthCheckTimeout);
      if (statusCode == _httpOkStatus) {
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
        final String previousModel = selectedModel;
        if (selectedModel.isNotEmpty &&
            !availableModels.any((Map<String, dynamic> model) => model['name'] == selectedModel)) {
          // User's selected model is no longer available, reset to first available
          selectedModel = models.isNotEmpty ? models.first['name'] as String : '';
        } else if (selectedModel.isEmpty && models.isNotEmpty) {
          // No model selected yet, use the first available
          selectedModel = models.first['name'] as String;
        }
        // Chat history and context are stored per model, so the next launch must start on the same one.
        if (selectedModel != previousModel) {
          await saveSelectedModel(selectedModel);
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

  /// Persists chat history for the current model.
  static Future<void> saveChatHistory(List<ChatMessage> chatHistory) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (chatHistory.isNotEmpty) {
      await prefs.setString('$_chatHistoryKeyPrefix$selectedModel', _encodeChatHistory(chatHistory));
    } else {
      await prefs.remove('$_chatHistoryKeyPrefix$selectedModel');
    }
  }

  /// Loads chat history for the current model.
  static Future<List<ChatMessage>> loadChatHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString('$_chatHistoryKeyPrefix$selectedModel');
    if (historyString != null) {
      return _decodeChatHistory(historyString);
    }
    return <ChatMessage>[];
  }

  /// Re-saves every model's chat history in the current format, which drops the per-question
  /// prompt payloads older versions stored, and removes their saved conversation tokens. Those grew
  /// the preferences to hundreds of MB, and on macOS every preference write (such as the prompt
  /// draft saved on each keystroke) then took ~1s.
  static Future<void> compactSavedConversations() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> keys = prefs.getKeys().toList();
      for (final String key in keys.where((String key) => key.startsWith(_legacyConversationContextKeyPrefix))) {
        await prefs.remove(key);
      }
      for (final String key in keys.where((String key) => key.startsWith(_chatHistoryKeyPrefix))) {
        final String? saved = prefs.getString(key);
        if (saved == null) {
          continue;
        }
        final String compacted = _encodeChatHistory(_decodeChatHistory(saved));
        if (compacted != saved) {
          await prefs.setString(key, compacted);
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        module: 'ollama_service',
        operation: 'compactSavedConversations',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Serializes [chatHistory] to the JSON text stored in preferences.
  static String _encodeChatHistory(List<ChatMessage> chatHistory) {
    return jsonEncode(chatHistory.map((ChatMessage msg) => msg.toJson()).toList());
  }

  /// Parses chat history JSON text stored in preferences.
  static List<ChatMessage> _decodeChatHistory(String historyString) {
    final List<dynamic> historyList = jsonDecode(historyString) as List<dynamic>;
    return historyList.cast<Map<String, dynamic>>().map(ChatMessage.fromJson).toList();
  }

  /// Sends a payload to the local Ollama API and returns the decoded JSON response.
  static Future<Map<String, dynamic>> sendPayload(Map<String, dynamic> payload) async {
    // Use /api/generate, which takes the conversation as one prompt
    if (!payload.containsKey(SharedStrings.payloadKeyMessages)) {
      return _postJson(_generateUri, payload);
    }
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
        prompt.write(
          SharedStrings.promptPrefixAssistant + content + SharedStrings.lineFeed + SharedStrings.lineFeed,
        );
      }
    }

    final String promptText = prompt.toString();
    return _postJson(_generateUri, <String, dynamic>{
      'model': payload['model'],
      'prompt': promptText,
      'stream': false,
      'options': <String, int>{_optionNumCtx: contextWindowFor(promptText)},
    });
  }

  /// Sends [messages] and the [tools] the model may call to Ollama's chat API, and returns the decoded
  /// reply: its `message` holds either the answer or the tool calls the model wants run.
  static Future<Map<String, dynamic>> sendChat({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
    required int contextWindow,
  }) {
    return _postJson(_chatUri, <String, dynamic>{
      'model': selectedModel,
      'messages': messages,
      if (tools.isNotEmpty) 'tools': tools,
      'stream': false,
      'options': <String, Object>{_optionNumCtx: contextWindow, _optionTemperature: _toolChatTemperature},
    });
  }

  /// Returns true when Ollama lists the `tools` capability for [model], so it can call the app's tools;
  /// false when it does not or Ollama cannot say. Answers are remembered per model.
  static Future<bool> supportsTools(String model) async {
    final bool? known = _toolSupportByModel[model];
    if (known != null) {
      return known;
    }
    try {
      final Map<String, dynamic> info = await _postJson(_showUri, <String, dynamic>{'model': model});
      final List<dynamic> capabilities = (info[_keyCapabilities] as List<dynamic>?) ?? <dynamic>[];
      return _toolSupportByModel[model] = capabilities.contains(_capabilityTools);
    } catch (e) {
      AppLogger.warning(module: 'ollama_service', operation: 'supportsTools', message: e.toString());
      return false;
    }
  }

  /// POSTs [body] as JSON to [uri] and returns the decoded JSON reply; [cancelPayload] aborts it.
  static Future<Map<String, dynamic>> _postJson(Uri uri, Map<String, dynamic> body) {
    return _withClient((HttpClient client) async {
      _payloadClient = client;
      final HttpClientRequest request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode(body)));
      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode != _httpOkStatus) {
        throw Exception('HTTP ${response.statusCode}: $responseBody');
      }
      return jsonDecode(responseBody) as Map<String, dynamic>;
    });
  }

  /// Aborts the [sendPayload] or [sendChat] request in flight, if any; closing the connection makes
  /// Ollama stop working on it, and the pending call throws.
  static void cancelPayload() {
    _payloadClient?.close(force: true);
  }

  /// Returns the context window (`num_ctx`) to request for [prompt]: the smallest power of two
  /// that fits the estimated prompt tokens plus an answer, between [_minContextTokens] and
  /// [_maxContextTokens]. Powers of two keep the size stable across similar prompts, since a new
  /// size makes Ollama reload the model.
  static int contextWindowFor(String prompt) {
    final int neededTokens = (prompt.length / _estimatedCharsPerToken).ceil() + _answerTokenReserve;
    int window = _minContextTokens;
    while (window < neededTokens && window < _maxContextTokens) {
      window *= _contextWindowGrowthFactor;
    }
    return window;
  }

  /// Local Ollama endpoint that lists installed models; also used as a health check.
  static final Uri _tagsUri = Uri.parse('http://localhost:11434/api/tags');

  /// Local Ollama endpoint that completes a single prompt.
  static final Uri _generateUri = Uri.parse('http://localhost:11434/api/generate');

  /// Local Ollama endpoint that continues a conversation and can call tools.
  static final Uri _chatUri = Uri.parse('http://localhost:11434/api/chat');

  /// Local Ollama endpoint that describes a model, including its capabilities.
  static final Uri _showUri = Uri.parse('http://localhost:11434/api/show');

  /// Model names already checked by [supportsTools], with the answer.
  static final Map<String, bool> _toolSupportByModel = <String, bool>{};

  /// Returns true when the local Ollama API answers the model list request in time.
  static Future<bool> _isServerResponding() {
    return _withClient((HttpClient client) async {
      final HttpClientResponse response = await (await client.getUrl(_tagsUri)).close();
      await response.drain<void>();
      return response.statusCode == _httpOkStatus;
    }).timeout(_healthCheckTimeout);
  }

  /// Runs [action] with a new [HttpClient] that times out when connecting and is always closed.
  static Future<T> _withClient<T>(Future<T> Function(HttpClient client) action) async {
    final HttpClient client = HttpClient()..connectionTimeout = _connectionTimeout;
    try {
      return await action(client);
    } finally {
      client.close();
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
