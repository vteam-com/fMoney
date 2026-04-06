// ignore: fcheck_one_class_per_file
import 'dart:async';
import 'dart:convert';

import 'package:money/data/models/ai_chat_types.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:money/providers/ollama_service.dart';
import 'package:money/shared/domain/account_domain.dart';
import 'package:money/shared/domain/data_domain.dart';
import 'package:money/shared/domain/transaction_domain.dart';
import 'package:money/views/home/ai/view_ai_chat_message.dart';
import 'package:money/views/home/ai/view_ai_header.dart';
import 'package:money/views/home/ai/view_ai_instructions.dart';
import 'package:money/widgets/components/processing_indicator.dart';
import 'package:money/widgets/components/text_title.dart';
import 'package:money/widgets/pure/chat_input_area.dart';
import 'package:money/widgets/pure/my_svg.dart';
import 'package:money/widgets/pure/view_widget.dart';
import 'package:money/widgets/pure/working.dart';

const double _checkingSpacing = 32.0;
const double _checkingIconSize = 64.0;

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
/// ViewAI() // Uses default service implementation
/// ViewAI(ollamaService: customService) // Uses custom service for testing
/// ```
class ViewAI extends ViewWidget {
  const ViewAI({super.key, this.ollamaService});

  /// Optional Ollama service to inject (mainly for testing)
  final OllamaServiceInterface? ollamaService;

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
/// Interface for Ollama service to enable testing with dependency injection
abstract class OllamaServiceInterface {
  /// Available models returned by the Ollama service.
  List<Map<String, dynamic>> get availableModels;

  /// Currently selected model name.
  String get selectedModel;

  /// Sets the currently selected model name.
  set selectedModel(String value);

  /// Returns true if Ollama is installed on this system.
  Future<bool> checkIfOllamaInstalled();

  /// Returns true if the Ollama HTTP API is reachable.
  Future<bool> checkIfOllamaRunning();

  /// Initiates Ollama installation.
  Future<void> installOllama();

  /// Starts the Ollama service.
  Future<void> startOllama();

  /// Loads available models from Ollama.
  Future<List<Map<String, dynamic>>> loadAvailableModels();

  /// Loads the last selected model from persistence.
  Future<void> getLastUserSelectedModel();

  /// Persists the selected model.
  Future<void> saveSelectedModel(String model);

  /// Loads the conversation context for the selected model.
  Future<List<int>?> loadConversationContext();

  /// Persists the conversation context for the selected model.
  Future<void> saveConversationContext(List<int>? context);

  /// Loads stored chat history for the selected model.
  Future<List<ChatMessage>> loadChatHistory();

  /// Persists chat history for the selected model.
  Future<void> saveChatHistory(List<ChatMessage> chatHistory);

  /// Sends an inference payload to Ollama.
  Future<Map<String, dynamic>> sendPayload(Map<String, dynamic> payload);

  /// Checks Ollama status and returns installation/running info.
  Future<OllamaStatus> checkOllamaStatus();
}

/// Implements the Ollama service interface by delegating to static methods
class OllamaServiceImpl implements OllamaServiceInterface {
  @override
  List<Map<String, dynamic>> get availableModels => OllamaService.availableModels;

  @override
  String get selectedModel => OllamaService.selectedModel;

  @override
  set selectedModel(String value) => OllamaService.selectedModel = value;

  @override
  Future<bool> checkIfOllamaInstalled() => OllamaService.checkIfOllamaInstalled();

  @override
  Future<bool> checkIfOllamaRunning() => OllamaService.checkIfOllamaRunning();

  @override
  Future<void> installOllama() => OllamaService.installOllama();

  @override
  Future<void> startOllama() => OllamaService.startOllama();

  @override
  Future<List<Map<String, dynamic>>> loadAvailableModels() => OllamaService.loadAvailableModels();

  @override
  Future<void> getLastUserSelectedModel() => OllamaService.getLastUserSelectedModel();

  @override
  Future<void> saveSelectedModel(String model) => OllamaService.saveSelectedModel(model);

  @override
  Future<List<int>?> loadConversationContext() => OllamaService.loadConversationContext();

  @override
  Future<void> saveConversationContext(List<int>? context) => OllamaService.saveConversationContext(context);

  @override
  Future<List<ChatMessage>> loadChatHistory() => OllamaService.loadChatHistory();

  @override
  Future<void> saveChatHistory(List<ChatMessage> chatHistory) => OllamaService.saveChatHistory(chatHistory);

  @override
  Future<Map<String, dynamic>> sendPayload(Map<String, dynamic> payload) => OllamaService.sendPayload(payload);

  @override
  Future<OllamaStatus> checkOllamaStatus() => OllamaService.checkOllamaStatus();
}

/// State for view ai.
class ViewAIState extends ViewWidgetState<ViewAI> {
  /// Service instance to use (defaults to static implementation but can be injected for testing)
  late OllamaServiceInterface _ollamaService;

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
  List<ChatMessage> _chatHistory = <ChatMessage>[];

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
    _ollamaService = widget.ollamaService ?? OllamaServiceImpl();

    // Load the selected model from preferences first
    _ollamaService.getLastUserSelectedModel().then((final _) async {
      try {
        // Load conversation context and chat history for the selected model
        _conversationContext = await _ollamaService.loadConversationContext();
        _chatHistory = await _ollamaService.loadChatHistory();
      } catch (e) {
        // Handle errors gracefully by using empty/default values
        _conversationContext = null;
        _chatHistory = <ChatMessage>[];
        debugPrint('Error loading chat history: $e');
      }
      _checkOllamaStatus();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolls the chat list to the bottom after the next frame.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: DurationInMs.normal),
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
      availableModels: _ollamaService.availableModels,
      selectedModel: _ollamaService.selectedModel,
      onModelSelected: (final String selectedModel) async {
        setState(() {}); // Refresh to update the selected model display
        _ollamaService.selectedModel = selectedModel;
        await _ollamaService.saveSelectedModel(selectedModel);
        // Load context and chat history for the new model
        _conversationContext = await _ollamaService.loadConversationContext();
        _chatHistory = await _ollamaService.loadChatHistory();
      },
      onClearChat: () async {
        setState(() {
          _chatHistory.clear();
          _conversationContext = null;
        });
        // Save the cleared context and chat history
        await _ollamaService.saveConversationContext(null);
        await _ollamaService.saveChatHistory(<ChatMessage>[]);
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
          spacing: _checkingSpacing,
          children: <Widget>[
            MySvg(
              assetName: 'ollama.svg',
              size: _checkingIconSize,
              color: getColorTheme(context).primary,
            ),
            Text(AppL10n.tr(AppTranslationKeys.checkingOllamaStatus)),
            const WorkingIndicator(
              size: _checkingIconSize,
            ),
          ],
        ),
      );
    }

    if (!_isOllamaInstalled || !_isOllamaRunning) {
      return ViewAIInstructions(
        isOllamaInstalled: _isOllamaInstalled,
        isOllamaRunning: _isOllamaRunning,
        onInstall: () => _ollamaService.installOllama(),
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
            onCancel: () async {
              _cancelled = true;
              _appendChatHistory(AppL10n.tr(AppTranslationKeys.requestWasCancelled), ChatFrom.ai);
              await _ollamaService.saveChatHistory(_chatHistory);
              setState(() {
                _isProcessingPrompt = false;
              });
            },
            inputController: _textController,
          ),
        ],
      ),
    );
  }

  /// Submits a user prompt to Ollama and appends responses to chat history.
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
      'model': _ollamaService.selectedModel,
      'messages': <Map<String, String>>[
        <String, String>{
          'role': SharedStrings.payloadRoleUser,
          'content': aiPrompt,
        },
      ],
      'stream': false,
    };

    // Add conversation context to payload if it exists and has content
    if (_conversationContext != null && _conversationContext!.isNotEmpty) {
      payload[SharedStrings.payloadKeyContext] = _conversationContext;
    }

    // Add user message to chat history
    _appendChatHistory(fullPrompt, ChatFrom.user, payload);
    await _ollamaService.saveChatHistory(_chatHistory);
    setState(() {
      _isProcessingPrompt = true;
    });

    try {
      if (_cancelled) {
        return;
      }

      final Map<String, dynamic> jsonResponse = await _ollamaService.sendPayload(payload);

      if (_cancelled) {
        return;
      }

      if (jsonResponse.containsKey(SharedStrings.payloadKeyResponse)) {
        final String aiResponse = jsonResponse[SharedStrings.payloadKeyResponse] as String;

        // Update conversation context with the returned context
        if (jsonResponse.containsKey(SharedStrings.payloadKeyContext)) {
          _conversationContext = (jsonResponse[SharedStrings.payloadKeyContext] as List<dynamic>).cast<int>();
          // Save updated context to persistent storage
          await _ollamaService.saveConversationContext(_conversationContext);
        }

        if (!_cancelled) {
          _appendChatHistory(aiResponse.trim(), ChatFrom.ai, payload);
          setState(() {
            _isProcessingPrompt = false;
          });
          // Save updated chat history
          await _ollamaService.saveChatHistory(_chatHistory);
        }
      } else {
        if (!_cancelled) {
          _appendChatHistory(AppL10n.tr(AppTranslationKeys.errorInvalidResponseFromOllama), ChatFrom.ai);
          await _ollamaService.saveChatHistory(_chatHistory);
          setState(() {
            _isProcessingPrompt = false;
          });
        }
      }
    } catch (e) {
      if (!_cancelled) {
        _appendChatHistory(
          AppL10n.tr(
            AppTranslationKeys.errorWithReason,
            params: <String, String>{'reason': e.toString()},
          ),
          ChatFrom.ai,
        );
        await _ollamaService.saveChatHistory(_chatHistory);
        setState(() {
          _isProcessingPrompt = false;
        });
      }
    }
    _cancelled = false;
  }

  /// Appends a message to chat history and triggers UI update.
  ///
  /// [text] is the message text to append.
  /// [source] is the source of the message (user or AI).
  /// [payload] is the payload sent to Ollama, if any.
  void _appendChatHistory(
    final String text,
    ChatFrom source, [
    Map<String, dynamic>? payload,
  ]) {
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

  /// Checks Ollama installation/running status and updates UI state.
  Future<void> _checkOllamaStatus() async {
    setState(() => _isChecking = true);

    try {
      final OllamaStatus status = await _ollamaService.checkOllamaStatus();
      _isOllamaInstalled = status.isInstalled;
      _isOllamaRunning = status.isRunning;
    } catch (e) {
      debugPrint('Ollama check error: $e');
      _isOllamaInstalled = false;
      _isOllamaRunning = false;
    }

    setState(() => _isChecking = false);
  }

  /// Builds the chat list view including history and processing indicator.
  Widget _chatListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(SizeForPadding.xlarge),
      reverse: false,
      itemCount: _chatHistory.length + (_isProcessingPrompt ? 1 : 0) + (_chatHistory.isEmpty ? 1 : 0),
      itemBuilder: (BuildContext _, int index) {
        if (_chatHistory.isEmpty && !_isProcessingPrompt) {
          return Center(
            child: TextTitle(AppL10n.tr(AppTranslationKeys.welcomeToYourAiAccountant)),
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

  /// Teaches the AI about accounts by sending recent transactions as context.
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
      final List<Transaction> transactions = Data().accounts.getTransactions(account).toList();
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
        'model': _ollamaService.selectedModel,
        'messages': <Map<String, String>>[
          <String, String>{
            'role': SharedStrings.payloadRoleUser,
            'content': accountData,
          },
        ],
        'stream': false,
      };

      // Add current context to payload if it exists
      if (_conversationContext != null && _conversationContext!.isNotEmpty) {
        payload[SharedStrings.payloadKeyContext] = _conversationContext;
      }

      try {
        final String teachingMessage = 'account "$accountName" with ${transactionsData.length} transactions.';

        _appendChatHistory(teachingMessage, ChatFrom.user, payload);

        final Map<String, dynamic> response = await _ollamaService.sendPayload(payload);

        if (response.containsKey(SharedStrings.payloadKeyContext)) {
          _conversationContext = (response[SharedStrings.payloadKeyContext] as List<dynamic>).cast<int>();
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
    await _ollamaService.saveConversationContext(_conversationContext);

    if (failed || _cancelled) {
      _appendChatHistory(
        _cancelled
            ? AppL10n.tr(AppTranslationKeys.teachingCancelled)
            : AppL10n.tr(AppTranslationKeys.teachingFailedPartially),
        ChatFrom.ai,
      );
      await _ollamaService.saveChatHistory(_chatHistory);
    } else {
      debugPrint(
        '📚 Taught AI about all ${accounts.length} accounts (context saved: ${_conversationContext?.length ?? 0} tokens)',
      );

      _appendChatHistory(
        AppL10n.tr(
          AppTranslationKeys.aiLearnedAboutAccountsAndTransactions,
          params: <String, String>{'count': accounts.length.toString()},
        ),
        ChatFrom.ai,
      );
      await _ollamaService.saveChatHistory(_chatHistory);
    }

    // Final setState to update UI
    if (mounted) {
      setState(() {
        _isProcessingPrompt = false;
      });
    }
  }
}
