import 'dart:async';
import 'package:money/core/widgets/my_svg.dart';
import 'package:money/core/widgets/text_title.dart';
import 'package:money/core/widgets/working.dart';
import 'package:money/data/models/money_objects/accounts/account.dart';
import 'package:money/data/models/money_objects/transactions/transaction.dart';
import 'package:money/data/storage/data/data.dart';
import 'package:money/views/home/sub_views/view.dart';
import 'package:money/views/home/sub_views/view_ai/ollama_service.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai_chat_message.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai_header.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai_input.dart';
import 'package:money/views/home/sub_views/view_ai/view_ai_instructions.dart';

/// ViewAI - AI-Powered Financial Assistant
///
/// This widget provides an AI chat interface for financial data analysis.
/// It integrates with Ollama to provide intelligent financial guidance based on
/// anonymized account patterns and user queries.
///
/// Features:
/// - Privacy-focused data sharing (pattern summaries only, no sensitive data)
/// - Incremental AI training (metadata-first, then pattern insights)
/// - Conversational AI interface with context retention
/// - Model selection and management
/// - Financial query assistance without exposing sensitive data
///
/// Architecture:
/// - Pattern recognition over data enumeration
/// - Metadata aggregation before sending to AI
/// - Privacy-by-design approach to financial AI
///
/// Example usage:
/// ```dart
/// ViewAI()
/// ```
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

/// State management for the ViewAI widget.
///
/// Handles all state changes for the AI assistant including:
/// - Ollama service status monitoring
/// - Chat conversation history
/// - Model selection and context management
/// - Anonymous data learning operations
///
/// This class manages complex async operations while maintaining UI responsiveness.
/// All financial data interactions prioritize user privacy through anonymization.
// ignore: always_specify_types
class ViewAIState extends ViewWidgetState {
  /// Creates the ViewAIState with initial empty state.
  ViewAIState();

  /// Whether Ollama AI service is installed on the system.
  bool _isOllamaInstalled = false;

  /// Whether Ollama service is currently running and available.
  bool _isOllamaRunning = false;

  /// Whether we are currently checking Ollama status.
  bool _isChecking = true;

  /// Whether an AI prompt is currently being processed.
  bool _isProcessingPrompt = false;

  /// Whether the current prompt processing should be cancelled.
  bool _cancelled = false;

  /// Controller for the text input field used for manual queries.
  final TextEditingController _textController = TextEditingController();

  /// History of all chat messages in the conversation.
  final List<ChatMessage> _chatHistory = <ChatMessage>[];

  /// Controller for the chat list scroll view to enable auto-scrolling.
  final ScrollController _scrollController = ScrollController();

  /// Conversation context tokens returned by Ollama for maintaining AI memory.
  /// Stored as nullable to indicate when no context exists yet.
  List<int>? _conversationContext;

  /// Initializes the AI assistant state.
  ///
  /// Loads the previously selected AI model from preferences and restores
  /// any saved conversation context for that model. Then checks the Ollama
  /// service status to ensure AI functionality is available.
  @override
  void initState() {
    super.initState();

    // Load the selected model from preferences first
    OllamaService.getLastUserSelectedModel().then((final _) async {
      // Load conversation context for the selected model
      _conversationContext = await OllamaService.loadConversationContext();
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
    final int questionCount = _chatHistory.where((final ChatMessage message) => message.type == ChatFrom.user).length;
    final int contextTokensCount = _conversationContext?.length ?? 0;

    return ViewAiHeader(
      availableModels: OllamaService.availableModels,
      selectedModel: OllamaService.selectedModel,
      onModelSelected: (final String selectedModel) async {
        setState(() {}); // Refresh to update the selected model display
        OllamaService.selectedModel = selectedModel;
        await OllamaService.saveSelectedModel(selectedModel);
        // Load context for the new model
        _conversationContext = await OllamaService.loadConversationContext();
      },
      onClearChat: () {
        setState(() {
          _chatHistory.clear();
          _conversationContext = null;
        });
        // Save the cleared context
        OllamaService.saveConversationContext(null);
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
            onSendPrompt: _submitPrompt,
            onTeachAI: () async => await teachAIAboutAccounts(),
            isProcessing: _isProcessingPrompt,
            onCancel: () {
              setState(() {
                _cancelled = true;
                _isProcessingPrompt = false;
                _appendChatHistory('Request was cancelled.', ChatFrom.ai);
              });
            },
            inputController: _textController,
          ),
        ],
      ),
    );
  }

  Future<void> _submitPrompt(final String promptAsked) async {
    if (!_isOllamaRunning) {
      setState(() {});
      return;
    }
    // Clear input textfield
    _textController.clear();

    String fullPrompt = promptAsked;

    // Ensure the prompt is valid UTF-8
    fullPrompt = utf8.decode(utf8.encode(fullPrompt));

    // Create direct prompt combining context instructions + user question
    final String aiPrompt =
        '''
You have been provided with financial data containing accounts and transactions (dates and amounts).

Answer this question directly using the financial data you learned: $fullPrompt

Guidelines:
- Use ONLY the account and transaction data provided
- Answer in plain English
- Be concise and direct
- List specific account names and amounts when asked
- Do NOT add generic financial advice
- Do NOT introduce yourself or talk about capabilities
- Focus only on the financial data and the specific question asked

Answer the question:''';

    final Map<String, dynamic> payload = <String, dynamic>{
      'model': OllamaService.selectedModel,
      'messages': <Map<String, String>>[
        <String, String>{
          'role': 'user',
          'content': aiPrompt,
        },
      ],
      'stream': false,
    };

    // Add conversation context to payload if it exists and has content
    if (_conversationContext != null && _conversationContext!.isNotEmpty) {
      payload['context'] = _conversationContext;
    }

    // Add user message to chat history
    setState(() {
      _appendChatHistory(fullPrompt, ChatFrom.user, payload);
      _isProcessingPrompt = true;
    });

    try {
      if (_cancelled) {
        return;
      }

      final Map<String, dynamic> jsonResponse = await OllamaService.sendPayload(payload);

      if (_cancelled) {
        return;
      }

      if (jsonResponse.containsKey('response')) {
        final String aiResponse = jsonResponse['response'] as String;

        // Update conversation context with the returned context
        if (jsonResponse.containsKey('context')) {
          _conversationContext = (jsonResponse['context'] as List<dynamic>).cast<int>();
          // Save updated context to persistent storage
          await OllamaService.saveConversationContext(_conversationContext);
        }

        if (!_cancelled) {
          setState(() {
            _isProcessingPrompt = false;
            _appendChatHistory(aiResponse.trim(), ChatFrom.ai, payload);
          });
        }
      } else {
        if (!_cancelled) {
          setState(() {
            _isProcessingPrompt = false;
            _appendChatHistory(
              'Error: Invalid response from Ollama',
              ChatFrom.ai,
            );
          });
        }
      }
    } catch (e) {
      if (!_cancelled) {
        setState(() {
          _isProcessingPrompt = false;
          _appendChatHistory('Error: $e', ChatFrom.ai);
        });
      }
    }
    _cancelled = false;
  }

  void _appendChatHistory(final String text, ChatFrom source, [Map<String, dynamic>? payload]) {
    _chatHistory.add(
      ChatMessage(
        message: text,
        type: source,
        timestamp: DateTime.now(),
        payloadSentToOllama: payload ?? <String, dynamic>{},
      ),
    );

    if (mounted) {
      setState(() {
        _scrollToBottom();
      });
    }
  }

  Future<void> _checkOllamaStatus() async {
    setState(() => _isChecking = true);

    try {
      final OllamaStatus status = await OllamaService.checkOllamaStatus();
      _isOllamaInstalled = status.isInstalled;
      _isOllamaRunning = status.isRunning;
    } catch (e) {
      debugPrint('Ollama check error: $e');
      _isOllamaInstalled = false;
      _isOllamaRunning = false;
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
          return const Center(
            child: TextTitle('Welcome to your AI Accountant'),
          );
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

  Future<void> teachAIAboutAccounts() async {
    if (mounted) {
      setState(() {
        _isProcessingPrompt = true;
      });
    }

    final List<Account> accounts = Data().accounts
        .getOpenRealAccounts()
        .where((final Account account) {
          return account.isActiveBankAccount();
        })
        // .take(3)
        .toList();

    if (accounts.isEmpty) {
      if (mounted) {
        setState(() {
          _isProcessingPrompt = false;
        });
      }
      return;
    }

    int successCount = 0;
    bool failed = false;

    for (final Account account in accounts) {
      if (_cancelled) {
        break;
      }

      final String accountName = account.fieldName.value;
      final List<Transaction> transactions = account.getTransaction();
      final List<String> transactionsData = transactions
          .where((final Transaction t) => t.dateTimeAsString.compareTo('2023-12-31') > -1)
          .map((final Transaction t) => '${t.dateTimeAsString},${t.amountAsString}')
          .toList();

      final String accountData =
          '''
Here is account data in compact format. Memorize this for future calculations:

ACCOUNT:$accountName
TRANSACTIONS:${transactionsData.join(';')}
---''';

      final Map<String, dynamic> payload = <String, dynamic>{
        'model': OllamaService.selectedModel,
        'messages': <Map<String, String>>[
          <String, String>{
            'role': 'user',
            'content': accountData,
          },
        ],
        'stream': false,
      };

      // Add current context to payload if it exists
      if (_conversationContext != null && _conversationContext!.isNotEmpty) {
        payload['context'] = _conversationContext;
      }

      try {
        final String teachingMessage = 'Acocunt "$accountName" with ${transactionsData.length} transactions.';

        _appendChatHistory(teachingMessage, ChatFrom.user, payload);

        final Map<String, dynamic> response = await OllamaService.sendPayload(payload);

        if (response.containsKey('context')) {
          _conversationContext = (response['context'] as List<dynamic>).cast<int>();
          successCount++;
          debugPrint('📚 Sent account $accountName ($successCount/${accounts.length})');
        }
      } catch (e) {
        failed = true;
        debugPrint('📚 Error sending account $accountName: $e');
        break;
      }
    }

    // Save the final context
    await OllamaService.saveConversationContext(_conversationContext);

    if (failed || _cancelled) {
      _appendChatHistory(
        _cancelled ? 'Teaching cancelled.' : 'Teaching failed partially - some accounts may not be learned.',
        ChatFrom.ai,
      );
    } else {
      debugPrint(
        '📚 Taught AI about all ${accounts.length} accounts (context saved: ${_conversationContext?.length ?? 0} tokens)',
      );

      _appendChatHistory(
        'AI has learned about ${accounts.length} accounts and their transactions.',
        ChatFrom.ai,
      );
    }
  }
}
