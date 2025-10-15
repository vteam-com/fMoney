// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:money/core/helpers/string_helper.dart';
import 'package:money/core/widgets/box.dart';
import 'package:money/core/widgets/gaps.dart';
import 'package:money/core/widgets/my_segment.dart';
import 'package:money/core/widgets/text_title.dart';
import 'package:money/core/widgets/working.dart';
import 'package:money/data/models/money_objects/transactions/transaction.dart';
import 'package:money/data/storage/data/data.dart';
import 'package:money/views/home/sub_views/view.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai_chat_message.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai_model_selection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// Using a const for now, but this should be configurable and loaded dynamically
String modelToUseInOllama = 'martain7r/finance-llama-8b:q4_k_m'; //'gpt-oss:20b',

// Sub-widgets for better organization

class ViewAI extends ViewWidget {
  const ViewAI({super.key});

  @override
  State<ViewWidget> createState() => ViewAIState();

  @override
  String getClassNamePlural() => '';

  @override
  String getClassNameSingular() => '';

  @override
  String getDescription() => '';
}

// ignore: always_specify_types
class ViewAIState extends ViewWidgetState {
  ViewAIState();

  bool _isOllamaInstalled = false;
  bool _isOllamaRunning = false;
  bool _isChecking = true;
  bool _isProcessingPrompt = false;
  bool _cancelled = false;
  int _contextMode = 0;
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _chatHistory = <ChatMessage>[];
  final List<Map<String, dynamic>> _availableModels = <Map<String, dynamic>>[];
  late String _selectedModel;

  @override
  void initState() {
    super.initState();
    _loadSelectedModel();
    _checkOllamaStatus();
  }

  @override
  Widget buildHeader([final Widget? child]) {
    return ViewAIModelSelection(
      availableModels: _availableModels,
      selectedModel: _selectedModel,
      onModelSelected: (final String selectedModel) async {
        setState(() {
          _selectedModel = selectedModel;
          modelToUseInOllama = selectedModel;
        });
        await _saveSelectedModel(selectedModel);
      },
      onClearChat: () {
        setState(() {
          _chatHistory.clear();
        });
      },
    );
  }

  @override
  Widget buildViewContent(final Widget child) {
    if (_isChecking) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 32,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/ollama.svg',
              width: 64,
              height: 64,
              colorFilter: ColorFilter.mode(getColorTheme(context).primary, BlendMode.srcIn),
            ),
            const Text('Checking Ollama status...'),
            const WorkingIndicator(
              size: 64,
            ),
          ],
        ),
      );
    }

    if (!_isOllamaInstalled) {
      return _buildOllamaInstructions();
    }

    if (!_isOllamaRunning) {
      return _buildOllamaInstructions();
    }
    return _buildChatInterface();
  }

  Widget _buildOllamaInstructions() {
    return Center(
      child: Box(
        padding: SizeForPadding.large,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/ollama.svg',
              width: 64,
              height: 64,
              colorFilter: ColorFilter.mode(getColorTheme(context).primary, BlendMode.srcIn),
            ),
            gapLarge(),
            const TextTitle('Ollama AI Assistant'),
            gapMedium(),
            const Text(
              'Ollama is required to use the AI assistant. Click below to install it.',
              textAlign: TextAlign.center,
            ),
            gapLarge(),
            if (!_isOllamaInstalled)
              ElevatedButton(
                onPressed: _installOllama,
                child: const Text('Install Ollama now'),
              ),
            if (!_isOllamaRunning)
              ElevatedButton(
                onPressed: _checkOllamaStatus,
                child: const Text('Run Ollama'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInterface() {
    return Container(
      color: getColorTheme(context).surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: false,
              itemCount: _chatHistory.length + (_isProcessingPrompt ? 1 : 0) + (_chatHistory.isEmpty ? 1 : 0),
              itemBuilder: (BuildContext context, int index) {
                if (_chatHistory.isEmpty && !_isProcessingPrompt) {
                  return const Text('Welcome to your AI Accountant');
                }
                // Handle chat messages
                final int messageIndex = index - (_chatHistory.isEmpty ? 1 : 0);

                if (messageIndex < _chatHistory.length) {
                  final ChatMessage message = _chatHistory[messageIndex];
                  final bool isUser = message.type == MessageType.user;

                  // Only apply truncation to AI messages, not user messages
                  final bool shouldTruncate = !isUser && message.message.trim().split('\n').length > 100;

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      child: Column(
                        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: <Widget>[
                          if (isUser)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                Icon(
                                  message.contextMode == 0 ? Icons.chat_bubble_outline : Icons.data_object,
                                  color: getColorTheme(context).primary,
                                  size: 16,
                                ),
                                gapSmall(),
                                Text(
                                  message.contextMode == 0 ? 'Generic' : 'Data context',
                                  style: TextStyle(
                                    color: getColorTheme(context).primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                ...<Widget>[
                                  gapSmall(),
                                  IconButton(
                                    onPressed: () {
                                      _showPromptPopup(message.payloadSentToOllama);
                                    },
                                    icon: Icon(
                                      Icons.info_outline,
                                      color: getColorTheme(context).primary,
                                      size: 16,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      maxWidth: 24,
                                      maxHeight: 24,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? getColorTheme(context).primaryContainer
                                  : getColorTheme(context).surfaceContainerHighest,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                                bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                SelectableText(
                                  shouldTruncate && !message.isExpanded
                                      ? '${message.message.trim().split('\n').take(100).join('\n')}\n...'
                                      : message.message.trim(),
                                  style: TextStyle(
                                    color: isUser
                                        ? getColorTheme(context).onPrimaryContainer
                                        : getColorTheme(context).onSurface,
                                  ),
                                ),
                                if (shouldTruncate)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        message.isExpanded = !message.isExpanded;
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      message.isExpanded ? 'Read Less' : 'Read More',
                                      style: TextStyle(
                                        color: getColorTheme(context).primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  // Show processing indicator
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      decoration: BoxDecoration(
                        color: getColorTheme(context).surfaceContainerHighest,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(4),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'Thinking...',
                            style: TextStyle(
                              color: getColorTheme(context).onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          gapLarge(),
                          const WorkingIndicator(size: 20),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: getColorTheme(context).outline.withAlpha(100)),
              ),
            ),
            child: Column(
              spacing: 8,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: 600,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () => _sendUserPrompt('Analyze my spending patterns'),
                        child: const Text('Analyze spending'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _contextMode = 1;
                          _sendUserPrompt('Identify the largest single transaction amount in each account');
                        },
                        child: const Text('Largest transactions'),
                      ),
                      ElevatedButton(
                        onPressed: () => _sendUserPrompt('Predict future expenses'),
                        child: const Text('Expense predictions'),
                      ),
                    ],
                  ),
                ),
                Row(
                  spacing: 8,
                  children: <Widget>[
                    SizedBox(
                      width: 100,
                      child: mySegmentSelector(
                        direction: Axis.vertical,
                        showSelectedIcon: false,
                        segments: <ButtonSegment<int>>[
                          const ButtonSegment<int>(
                            value: 0,
                            label: Text('Generic'),
                          ),
                          const ButtonSegment<int>(
                            value: 1,
                            label: Text('All data'),
                          ),
                        ],
                        selectedId: _contextMode,
                        onSelectionChanged: (final int newSelection) {
                          setState(() {
                            _contextMode = newSelection;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Ask the AI assistant...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (final String text) {
                          _sendUserPrompt(text);
                        },
                      ),
                    ),

                    if (_isProcessingPrompt)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _cancelled = true;
                            _isProcessingPrompt = false;
                            _chatHistory.add(
                              ChatMessage(
                                message: 'Request was cancelled.',
                                type: MessageType.ai,
                                timestamp: DateTime.now(),
                                payloadSentToOllama: <String, dynamic>{},
                              ),
                            );
                          });
                        },
                        icon: Icon(Icons.cancel, color: getColorTheme(context).primary),
                      )
                    else
                      IconButton(
                        onPressed: () {
                          final String text = _textController.text;
                          if (text.isNotEmpty) {
                            _sendUserPrompt(text);
                          }
                        },
                        icon: Icon(Icons.send, color: getColorTheme(context).primary),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendUserPrompt(final String promptAsked) async {
    if (!_isOllamaRunning) {
      setState(() {});
      return;
    }

    String contextPrompt = '';
    if (_contextMode == 1) {
      contextPrompt = _getFinancialData();
    }

    // Create the full prompt based on context mode
    String fullPrompt = '\n$promptAsked\n${_contextMode == 1 ? contextPrompt : ''}';

    // Ensure the prompt is valid UTF-8
    fullPrompt = utf8.decode(utf8.encode(fullPrompt));

    // Prepare the JSON payload
    final Map<String, dynamic> payload = <String, dynamic>{
      'model': modelToUseInOllama,
      'system':
          "You are a professional financial analyst AI. Your only task is to read the provided transaction data and directly answer the user's question in plain English. Do NOT include reasoning, internal thoughts, <think> tags, explanations, or commentary. Only output the final result as concise natural sentences.",
      'prompt': 'Question: $fullPrompt',
      'stream': false, // Set to false for simplicity, response comes back all at once
    };

    // Add user message to chat history
    setState(() {
      _chatHistory.add(
        ChatMessage(
          message: promptAsked,
          type: MessageType.user,
          timestamp: DateTime.now(),
          contextMode: _contextMode,
          payloadSentToOllama: payload,
        ),
      );
      _isProcessingPrompt = true;
    });

    // Clear input field
    _textController.clear();

    try {
      // Send prompt to Ollama via HTTP API
      final Uri generateUrl = Uri.parse('http://localhost:11434/api/generate');
      final HttpClient client = HttpClient();

      // Create the HTTP request
      final HttpClientRequest request = await client.postUrl(generateUrl);

      // Write JSON-encoded body and set content-type (send as proper UTF-8 bytes)
      request.headers.contentType = ContentType.json;
      final List<int> utf8Body = utf8.encode(jsonEncode(payload));
      request.add(utf8Body);

      if (_cancelled) {
        return;
      }

      final HttpClientResponse response = await request.close();

      if (_cancelled) {
        return;
      }

      final String responseBody = await response.transform(utf8.decoder).join();

      if (_cancelled) {
        return;
      }

      if (response.statusCode == 200) {
        // Parse the JSON response
        final Map<String, dynamic> jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
        final String aiResponse = jsonResponse['response'] as String;
        if (!_cancelled) {
          setState(() {
            _isProcessingPrompt = false;
            _chatHistory.add(
              ChatMessage(
                message: aiResponse.trim(),
                type: MessageType.ai,
                timestamp: DateTime.now(),
                payloadSentToOllama: payload,
              ),
            );
          });
        }
      } else {
        if (!_cancelled) {
          setState(() {
            _isProcessingPrompt = false;
            _chatHistory.add(
              ChatMessage(
                message: 'Error: HTTP ${response.statusCode}',
                type: MessageType.ai,
                timestamp: DateTime.now(),
                payloadSentToOllama: <String, dynamic>{},
              ),
            );
          });
        }
      }
    } catch (e) {
      if (!_cancelled) {
        setState(() {
          _isProcessingPrompt = false;
          _chatHistory.add(
            ChatMessage(
              message: 'Error: $e',
              type: MessageType.ai,
              timestamp: DateTime.now(),
              payloadSentToOllama: <String, dynamic>{},
            ),
          );
        });
      }
    }
    _cancelled = false;
  }

  void _showPromptPopup(final Map<String, dynamic> jsonAsTextpayloadSentToOllama) {
    final String jsonAsText = const JsonEncoder.withIndent('  ').convert(jsonAsTextpayloadSentToOllama);

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Full Prompt Sent to AI'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            child: SingleChildScrollView(
              child: SelectableText(
                jsonAsText,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: <Widget>[
            IconButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: jsonAsText));
              },
              icon: const Icon(Icons.copy_all),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _getFinancialData() {
    final StringBuffer data = StringBuffer();

    try {
      final Map<String, List<Transaction>> transactionsByAccount = <String, List<Transaction>>{};

      for (final Transaction transaction in Data().transactions.iterableList()) {
        final String account = transaction.accountName;
        transactionsByAccount.putIfAbsent(account, () => <Transaction>[]).add(transaction);
      }
      data.writeln('Here is the input data its all the accounts with their their transactions as date, amount ');
      for (final MapEntry<String, List<Transaction>> entry in transactionsByAccount.entries) {
        final String accountName = entry.key;
        final List<Transaction> transactions = entry.value;

        data.writeln('Transactions in account "$accountName" ');

        for (final Transaction t in transactions) {
          data.writeln('${t.dateTimeAsString}, ${t.amountAsString}');
        }

        data.writeln('');
      }
    } catch (e) {
      data.writeln('Error loading transactions data');
    }

    // Updated prompt to clarify CSV includes headers and is not code/numeric input
    return data.toString();
  }

  Future<void> _checkOllamaStatus() async {
    setState(() => _isChecking = true);

    _isOllamaInstalled = false;
    _isOllamaRunning = false;

    try {
      // First check if Ollama is installed using shell command
      _isOllamaInstalled = await _checkIfOllamaInstalled();

      if (_isOllamaInstalled) {
        _isOllamaInstalled = true;
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

    setState(() => _isChecking = false);
  }

  Future<bool> _checkIfOllamaInstalled() async {
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

  Future<bool> _checkIfOllamaRunning() async {
    try {
      final Uri ollamaUrl = Uri.parse('http://localhost:11434/api/tags');
      final HttpClient client = HttpClient();
      final HttpClientRequest request = await client.getUrl(ollamaUrl);
      final HttpClientResponse response = await request.close();

      return (response.statusCode == 200);
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }
  }

  Future<void> _installOllama() async {
    // Open Ollama download page
    final Uri url = Uri.parse('https://ollama.com/download');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // Launch the macOS Ollama app directly (same as clicking it in Applications)
  Future<void> _startOllama() async {
    try {
      // Check if Ollama is already running
      final HttpClient client = HttpClient();
      try {
        final HttpClientRequest request = await client.getUrl(Uri.parse('http://localhost:11434/api/tags'));
        final HttpClientResponse response = await request.close();
        if (response.statusCode == 200) {
          print('Ollama is already running.');
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
          <String>['run', modelToUseInOllama],
          mode: ProcessStartMode.detached,
          environment: Platform.environment,
        );
        print('Launching Ollama silently on macOS...');
      } else if (Platform.isWindows) {
        // 🧩 Launch Ollama in the background (no console window)
        await Process.start(
          'cmd',
          <String>['/c', 'start', '/min', 'ollama', 'serve'],
          mode: ProcessStartMode.detached,
        );
        print('Launching Ollama silently on Windows...');
      } else if (Platform.isLinux) {
        // 🧩 Linux typically only has the CLI
        await Process.start(
          'ollama',
          <String>['serve'],
          mode: ProcessStartMode.detached,
        );
        print('Launching Ollama silently on Linux...');
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
        print('✅ Ollama started and responding.');
      } else {
        print('⚠️ Ollama started but not responding correctly.');
      }
      verifyClient.close();
    } catch (e) {
      print('❌ Failed to start Ollama: $e');
    }
  }

  Future<void> _loadAvailableModels() async {
    try {
      final HttpClient client = HttpClient();
      final HttpClientRequest request = await client.getUrl(Uri.parse('http://localhost:11434/api/tags'));
      final HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        final String responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
        final List<dynamic> models = jsonResponse['models'] as List<dynamic>;
        setState(() {
          _availableModels.clear();
          _availableModels.addAll(
            models.map((final dynamic model) => model as Map<String, dynamic>),
          );
          // Sort models by name
          _availableModels.sort(
            (final Map<String, dynamic> a, final Map<String, dynamic> b) =>
                stringCompareIgnoreCasing2(a['name'] as String, b['name'] as String),
          );
          _selectedModel = models.isNotEmpty ? models.first['name'] as String : modelToUseInOllama;
          modelToUseInOllama = _selectedModel;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading models: $e');
      }
    }
  }

  Future<void> _loadSelectedModel() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedModel = prefs.getString('selected_ollama_model') ?? modelToUseInOllama;
      modelToUseInOllama = _selectedModel;
    });
  }

  Future<void> _saveSelectedModel(final String model) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_ollama_model', model);
  }
}
