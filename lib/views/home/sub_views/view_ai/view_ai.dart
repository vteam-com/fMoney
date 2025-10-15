import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:money/core/widgets/gaps.dart';
import 'package:money/core/widgets/my_svg.dart';
import 'package:money/core/widgets/working.dart';
import 'package:money/data/models/money_objects/transactions/transaction.dart';
import 'package:money/data/storage/data/data.dart';
import 'package:money/views/home/sub_views/view.dart';
import 'package:money/views/home/sub_views/view_ai/ollama_service.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai_chat_message.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai_input.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai_instructions.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai_model_selection.dart';

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
  // Selected model is now managed in OllamaService

  @override
  void initState() {
    super.initState();

    // Load the selected model from preferences first
    OllamaService.getLastUserSelectedModel().then((final _) {
      _checkOllamaStatus();
    });
  }

  @override
  Widget buildHeader([final Widget? child]) {
    return ViewAIModelSelection(
      availableModels: OllamaService.availableModels,
      selectedModel: OllamaService.selectedModel,
      onModelSelected: (final String selectedModel) async {
        setState(() {}); // Refresh to update the selected model display
        OllamaService.selectedModel = selectedModel;
        await OllamaService.saveSelectedModel(selectedModel);
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
            MySvg(
              assetName: 'ollama.svg',
              size: 64,
              color: getColorTheme(context).primary,
            ),
            const Text('Checking Ollama status...'),
            const WorkingIndicator(
              size: 64,
            ),
          ],
        ),
      );
    }

    if (!_isOllamaInstalled || !_isOllamaRunning) {
      return ViewAIInstructions(
        isOllamaInstalled: _isOllamaInstalled,
        isOllamaRunning: _isOllamaRunning,
        onInstall: () => OllamaService.installOllama(),
        onCheckStatus: _checkOllamaStatus,
      );
    }

    return Container(
      color: getColorTheme(context).surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: _chatListView()),
          ChatInputArea(
            contextMode: _contextMode,
            onContextModeChanged: (int value) {
              setState(() {
                _contextMode = value;
              });
            },
            onSendPrompt: _sendUserPrompt,
            isProcessing: _isProcessingPrompt,
            onCancel: () {
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
      'model': OllamaService.selectedModel,
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
      _isOllamaInstalled = await OllamaService.checkIfOllamaInstalled();

      if (_isOllamaInstalled) {
        _isOllamaRunning = await OllamaService.checkIfOllamaRunning();
        if (!_isOllamaRunning) {
          await OllamaService.startOllama();
          _isOllamaRunning = await OllamaService.checkIfOllamaRunning();
        }

        // Get the list of models
        if (_isOllamaRunning) {
          await OllamaService.loadAvailableModels();
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Ollama check error: $e');
    }

    setState(() => _isChecking = false);
  }

  Widget _chatListView() {
    return ListView.builder(
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
    );
  }
}
