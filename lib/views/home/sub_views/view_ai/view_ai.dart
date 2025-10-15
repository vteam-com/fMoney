import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:money/core/widgets/my_svg.dart';
import 'package:money/core/widgets/working.dart';
import 'package:money/data/models/money_objects/transactions/transaction.dart';
import 'package:money/data/storage/data/data.dart';
import 'package:money/views/home/sub_views/view.dart';
import 'package:money/views/home/sub_views/view_ai/ollama_service.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai_chat_message.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai_header.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai_input.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai_instructions.dart';

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
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _chatHistory = <ChatMessage>[];
  final ScrollController _scrollController = ScrollController();
  List<int>? _conversationContext; // Store Ollama conversation context
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget buildHeader([final Widget? child]) {
    final int questionCount = _chatHistory
        .where((final ChatMessage message) => message.type == MessageType.user)
        .length;
    final int contextTokensCount = _conversationContext?.length ?? 0;

    return ViewAiHeader(
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
          _conversationContext = null;
        });
      },
      questionCount: questionCount,
      contextTokensCount: contextTokensCount,
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
          Expanded(
            child: _chatListView(),
          ),
          ChatInputArea(
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
            inputController: _textController,
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

    String fullPrompt = promptAsked;

    // Create the full prompt
    if (promptAsked == '#transactions') {
      fullPrompt += 'learn these transactions \n${_getFinancialData()}';
    }

    // Ensure the prompt is valid UTF-8
    fullPrompt = utf8.decode(utf8.encode(fullPrompt));

    // Prepare the JSON payload
    final Map<String, dynamic> payload = <String, dynamic>{
      'model': OllamaService.selectedModel,
      // 'system':
      //     "You are a professional financial analyst AI. Your only task is to read the provided transaction data and directly answer the user's question in plain English. Do NOT include reasoning, internal thoughts, <think> tags, explanations, or commentary. Only output the final result as concise natural sentences.",
      'prompt': fullPrompt,
      'stream': false, // Set to false for simplicity, response comes back all at once
    };

    // Include conversation context if available
    if (_conversationContext != null) {
      payload['context'] = _conversationContext;
    }

    // Add user message to chat history
    setState(() {
      _chatHistory.add(
        ChatMessage(
          message: fullPrompt,
          type: MessageType.user,
          timestamp: DateTime.now(),
          payloadSentToOllama: payload,
        ),
      );
      _isProcessingPrompt = true;
      _scrollToBottom();
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

        // Update conversation context with the returned context
        _conversationContext = (jsonResponse['context'] as List<dynamic>?)?.cast<int>();

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
            _scrollToBottom();
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

  String _getFinancialData() {
    final StringBuffer data = StringBuffer();

    try {
      final Map<String, List<Transaction>> transactionsByAccount = <String, List<Transaction>>{};

      for (final Transaction transaction in Data().transactions.iterableList()) {
        final String account = transaction.accountName;
        transactionsByAccount.putIfAbsent(account, () => <Transaction>[]).add(transaction);
      }
      data.writeln('Here are all my accounts with their transactions as date, amount \n');
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
      controller: _scrollController,
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
          return ChatMessageWidget(
            message: message,
            onToggleExpanded: () => setState(() {
              message.isExpanded = !message.isExpanded;
            }),
          );
        } else {
          // Show processing indicator
          return const ProcessingIndicator();
        }
      },
    );
  }
}
