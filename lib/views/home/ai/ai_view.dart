import 'dart:async';
import 'dart:convert';

import 'package:money/data/models/account_type_helper.dart';
import 'package:money/data/models/account_types_enum.dart';
import 'package:money/data/models/ai_chat_model.dart';
import 'package:money/data/services/ollama_service.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_logger_helper.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/account_entity.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';
import 'package:money/views/home/ai/ai_chat_message_widget.dart';
import 'package:money/views/home/ai/ai_header_widget.dart';
import 'package:money/views/home/ai/ai_instructions_widget.dart';
import 'package:money/widgets/components/processing_indicator_widget.dart';
import 'package:money/widgets/components/text_title_widget.dart';
import 'package:money/widgets/pure/chat_input_area_widget.dart';
import 'package:money/widgets/pure/my_svg_widget.dart';
import 'package:money/widgets/pure/view_widget.dart';
import 'package:money/widgets/pure/working_indicator_widget.dart';
import 'package:money/widgets/state/preferences_controller.dart';

const double _checkingSpacing = 32.0;
const double _checkingIconSize = 64.0;
const String _promptAccountSectionHeader = 'Selected account context as JSON (use only this data in your answer):';
const String _promptNoAccountDataLine = 'No selected account data is available.';
const String _promptContextVersion = '1.0';
const int _maxTransactionsPerAccountInPrompt = 250;

/// How many of the latest chat messages (questions and answers) are recapped in each prompt.
const int _recapMessageCount = 6;

/// Introduces the recap of earlier messages in the prompt.
const String _promptRecapHeader = 'Earlier messages in this conversation (for follow-up questions):';
final String _aiPromptDraftPreferenceKey = ViewId.viewAI.getViewPreferenceId(settingKeyAiPromptDraftText);
final String _aiAllAccountsSelectedPreferenceKey = ViewId.viewAI.getViewPreferenceId('aiAllAccountsSelected');
final String _aiSelectedAccountIdsPreferenceKey = ViewId.viewAI.getViewPreferenceId('aiSelectedAccountIds');

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
class ViewAI extends ViewWidget {
  const ViewAI({super.key});

  @override
  State<ViewWidget> createState() => _ViewAIState();
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
class _ViewAIState extends ViewWidgetState<ViewAI> {
  /// Whether Ollama AI service is installed on the system.
  bool _isOllamaInstalled = false;

  /// Whether Ollama service is currently running and available.
  bool _isOllamaRunning = false;

  /// Whether we are currently checking Ollama status.
  bool _isChecking = true;

  /// Whether an AI prompt is currently being processed.
  bool _isProcessingPrompt = false;

  /// Identifies the prompt being answered; Cancel and each new prompt bump it so a late reply is dropped.
  int _requestId = 0;

  /// Controller for the text input field used for manual queries.
  final TextEditingController _textController = TextEditingController();

  /// History of all chat messages in the conversation.
  List<ChatMessage> _chatHistory = <ChatMessage>[];

  /// Controller for the chat list scroll view to enable auto-scrolling.
  final ScrollController _scrollController = ScrollController();

  /// Size in tokens of the last answered prompt, as reported by Ollama; 0 until one is answered.
  int _lastPromptTokenCount = 0;

  /// True when all available accounts are selected for chat context.
  bool _allAccountsSelected = true;

  /// Explicitly selected account ids when [_allAccountsSelected] is false.
  final Set<int> _selectedAccountIds = <int>{};

  /// Persists prompt draft text changes as the user types.
  void _onPromptDraftChanged() {
    unawaited(
      PreferenceController.to.setString(
        _aiPromptDraftPreferenceKey,
        _textController.text,
        true,
      ),
    );
  }

  /// Restores prompt draft text from preferences into the input field.
  void _restorePromptDraft() {
    final String draft = PreferenceController.to.getString(_aiPromptDraftPreferenceKey, '');
    if (draft.isEmpty) {
      return;
    }

    _textController
      ..text = draft
      ..selection = TextSelection.collapsed(offset: draft.length);
  }

  /// Persists account selection state used for AI prompt context.
  void _persistPromptAccountSelection() {
    final String selectedAccountIdsAsString = _selectedAccountIds.join(',');
    unawaited(PreferenceController.to.setBool(_aiAllAccountsSelectedPreferenceKey, _allAccountsSelected));
    unawaited(
      PreferenceController.to.setString(
        _aiSelectedAccountIdsPreferenceKey,
        selectedAccountIdsAsString,
        true,
      ),
    );
  }

  /// Restores account selection state from preferences for AI prompt context.
  void _restorePromptAccountSelection() {
    final bool storedAllAccountsSelected = PreferenceController.to.getBool(_aiAllAccountsSelectedPreferenceKey, true);
    final String selectedAccountIdsAsString = PreferenceController.to.getString(
      _aiSelectedAccountIdsPreferenceKey,
      '',
    );

    final Set<int> availableAccountIds = _getSelectablePromptAccounts()
        .map((Account account) => account.uniqueId)
        .toSet();
    final Set<int> restoredSelectedIds = selectedAccountIdsAsString
        .split(',')
        .map((String value) => int.tryParse(value))
        .whereType<int>()
        .where(availableAccountIds.contains)
        .toSet();

    _selectedAccountIds
      ..clear()
      ..addAll(restoredSelectedIds);

    _allAccountsSelected = storedAllAccountsSelected || _selectedAccountIds.isEmpty;
    if (_allAccountsSelected) {
      _selectedAccountIds.clear();
    }

    _persistPromptAccountSelection();
  }

  /// Initializes the AI assistant state.
  ///
  /// Loads the previously selected AI model from preferences and restores
  /// any saved conversation context for that model. Then checks the Ollama
  /// service status to ensure AI functionality is available.
  @override
  void initState() {
    super.initState();
    _restorePromptDraft();
    _restorePromptAccountSelection();
    _textController.addListener(_onPromptDraftChanged);

    // Load the selected model from preferences first
    OllamaService.getLastUserSelectedModel().then((_) async {
      // Histories saved by older versions can be huge enough to make every preference write slow.
      await OllamaService.compactSavedConversations();
      if (!mounted) {
        return;
      }
      // The status check can switch models (none saved yet, or the saved one is gone),
      // and history is kept per model, so load the conversation after it.
      await _checkOllamaStatus();
      await _loadModelConversation();
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_onPromptDraftChanged);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolls the chat list to the bottom after the next frame.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
  Widget buildHeader([Widget? child]) {
    final int questionCount = _chatHistory.where((ChatMessage message) => message.type == ChatFrom.user).length;

    return ViewAiHeader(
      availableModels: OllamaService.availableModels,
      selectedModel: OllamaService.selectedModel,
      onModelSelected: (String selectedModel) async {
        setState(() {}); // Refresh to update the selected model display
        OllamaService.selectedModel = selectedModel;
        await OllamaService.saveSelectedModel(selectedModel);
        await _loadModelConversation();
      },
      onClearChat: () async {
        setState(() {
          _chatHistory.clear();
          _lastPromptTokenCount = 0;
        });
        await OllamaService.saveChatHistory(<ChatMessage>[]);
      },
      questionCount: questionCount,
      contextTokensCount: _lastPromptTokenCount,
    );
  }

  @override
  Widget buildViewContent(Widget child) {
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
            isProcessing: _isProcessingPrompt,
            onCancel: () async {
              _requestId++;
              OllamaService.cancelPayload();
              _appendChatHistory(AppL10n.tr(AppTranslationKeys.requestWasCancelled), ChatFrom.ai);
              await OllamaService.saveChatHistory(_chatHistory);
              setState(() {
                _isProcessingPrompt = false;
              });
            },
            inputController: _textController,
            accountGroupsByLabel: _getPromptAccountGroups(),
            selectedAccountIds: _selectedAccountIds,
            selectAllAccounts: _allAccountsSelected,
            onToggleAccountSelection: _toggleAccountSelection,
            onToggleSelectAllAccounts: _selectAllAccounts,
          ),
        ],
      ),
    );
  }

  /// Submits a user prompt to Ollama and appends responses to chat history.
  Future<void> _submitPrompt(String promptAsked) async {
    if (!_isOllamaRunning) {
      setState(() {});
      return;
    }
    // Clear input textfield
    _textController.clear();
    await PreferenceController.to.remove(_aiPromptDraftPreferenceKey);

    String fullPrompt = promptAsked;

    // Ensure the prompt is valid UTF-8
    fullPrompt = utf8.decode(utf8.encode(fullPrompt));

    // Create direct prompt combining context instructions + user question
    final List<Account> selectedAccounts = _getSelectedPromptAccounts();
    final String accountContextForPrompt = _buildPromptAccountContext(selectedAccounts);

    // The account data comes first so follow-ups with the same selection start with the same text,
    // which Ollama reuses from its cache instead of reading it again.
    final String aiPrompt =
        '''
You have been provided with financial data containing accounts and transactions (dates and amounts).

  $_promptAccountSectionHeader
  $accountContextForPrompt
${_buildConversationRecap()}
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
          'role': SharedStrings.payloadRoleUser,
          'content': aiPrompt,
        },
      ],
      'stream': false,
    };

    // Add user message to chat history
    final int requestId = ++_requestId;
    _appendChatHistory(fullPrompt, ChatFrom.user, payload);
    await OllamaService.saveChatHistory(_chatHistory);
    if (!mounted) {
      return;
    }
    setState(() {
      _isProcessingPrompt = true;
    });

    /// Returns true while this prompt is still the one the view is waiting for (not cancelled, not left).
    bool isCurrent() => mounted && requestId == _requestId;

    try {
      final Map<String, dynamic> jsonResponse = await OllamaService.sendPayload(payload);

      if (!isCurrent()) {
        return;
      }

      if (jsonResponse.containsKey(SharedStrings.payloadKeyResponse)) {
        final String aiResponse = jsonResponse[SharedStrings.payloadKeyResponse] as String;
        _appendChatHistory(aiResponse.trim(), ChatFrom.ai);
        setState(() {
          _isProcessingPrompt = false;
          _lastPromptTokenCount = (jsonResponse[SharedStrings.payloadKeyPromptEvalCount] as int?) ?? 0;
        });
        // Save updated chat history
        await OllamaService.saveChatHistory(_chatHistory);
      } else {
        _appendChatHistory(AppL10n.tr(AppTranslationKeys.errorInvalidResponseFromOllama), ChatFrom.ai);
        await OllamaService.saveChatHistory(_chatHistory);
        if (mounted) {
          setState(() {
            _isProcessingPrompt = false;
          });
        }
      }
    } catch (e) {
      if (!isCurrent()) {
        return;
      }
      _appendChatHistory(
        AppL10n.tr(
          AppTranslationKeys.errorWithReason,
          params: <String, String>{'reason': e.toString()},
        ),
        ChatFrom.ai,
      );
      await OllamaService.saveChatHistory(_chatHistory);
      if (mounted) {
        setState(() {
          _isProcessingPrompt = false;
        });
      }
    }
  }

  /// Loads the selected model's saved chat history, then shows it.
  Future<void> _loadModelConversation() async {
    List<ChatMessage> chatHistory;
    try {
      chatHistory = await OllamaService.loadChatHistory();
    } catch (e) {
      // Fall back to an empty conversation rather than failing the view.
      chatHistory = <ChatMessage>[];
      AppLogger.error(module: 'ai_view', operation: '_loadModelConversation', error: e);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _chatHistory = chatHistory;
      _lastPromptTokenCount = 0;
    });
  }

  /// Returns the last [_recapMessageCount] chat messages as text under [_promptRecapHeader], or an
  /// empty string when there are none, so follow-up questions keep their meaning without re-sending
  /// earlier prompts' account data.
  String _buildConversationRecap() {
    if (_chatHistory.isEmpty) {
      return '';
    }
    final int firstIndex = _chatHistory.length > _recapMessageCount ? _chatHistory.length - _recapMessageCount : 0;
    final StringBuffer recap = StringBuffer()
      ..writeln()
      ..writeln(_promptRecapHeader);
    for (final ChatMessage message in _chatHistory.sublist(firstIndex)) {
      final String prefix = message.type == ChatFrom.user
          ? SharedStrings.promptPrefixUser
          : SharedStrings.promptPrefixAssistant;
      recap.writeln('$prefix${message.message}');
    }
    return recap.toString();
  }

  /// Returns sorted, open real accounts available for AI prompt context.
  List<Account> _getSelectablePromptAccounts() {
    final List<Account> accounts = Data().accounts.getOpenRealAccounts();
    accounts.sort(
      (Account left, Account right) =>
          left.fieldName.value.toLowerCase().compareTo(right.fieldName.value.toLowerCase()),
    );
    return accounts;
  }

  /// Returns account options grouped by account type label.
  Map<String, Map<int, String>> _getPromptAccountGroups() {
    final List<Account> accounts = _getSelectablePromptAccounts();
    final Map<AccountType, List<Account>> groupedAccounts = <AccountType, List<Account>>{};

    for (final Account account in accounts) {
      final List<Account> bucket = groupedAccounts.putIfAbsent(account.fieldType.value, () => <Account>[]);
      bucket.add(account);
    }

    final List<AccountType> sortedTypes = groupedAccounts.keys.toList()
      ..sort(
        (AccountType left, AccountType right) =>
            getTypeAsText(left).toLowerCase().compareTo(getTypeAsText(right).toLowerCase()),
      );

    return <String, Map<int, String>>{
      for (final AccountType type in sortedTypes)
        getTypeAsText(type): <int, String>{
          for (final Account account in groupedAccounts[type]!) account.uniqueId: account.fieldName.value,
        },
    };
  }

  /// Returns accounts selected for inclusion in the AI prompt context.
  List<Account> _getSelectedPromptAccounts() {
    final List<Account> availableAccounts = _getSelectablePromptAccounts();
    if (_allAccountsSelected) {
      return availableAccounts;
    }

    final List<Account> selected = availableAccounts
        .where((Account account) => _selectedAccountIds.contains(account.uniqueId))
        .toList();

    // Keep context usable when stale selections no longer match current accounts.
    if (selected.isEmpty) {
      return availableAccounts;
    }

    return selected;
  }

  /// Marks all available accounts as selected for prompt context.
  void _selectAllAccounts() {
    setState(() {
      _allAccountsSelected = true;
      _selectedAccountIds.clear();
    });
    _persistPromptAccountSelection();
  }

  /// Toggles selection of a single account id for prompt context.
  void _toggleAccountSelection(int accountId) {
    setState(() {
      if (_allAccountsSelected) {
        _allAccountsSelected = false;
        _selectedAccountIds
          ..clear()
          ..add(accountId);
        return;
      }

      if (_selectedAccountIds.contains(accountId)) {
        _selectedAccountIds.remove(accountId);
      } else {
        _selectedAccountIds.add(accountId);
      }

      if (_selectedAccountIds.isEmpty) {
        _allAccountsSelected = true;
      }
    });
    _persistPromptAccountSelection();
  }

  /// Builds compact account and transaction context text for the current prompt.
  String _buildPromptAccountContext(List<Account> accounts) {
    if (accounts.isEmpty) {
      return _promptNoAccountDataLine;
    }

    final List<Map<String, Object>> accountsPayload = <Map<String, Object>>[];

    for (final Account account in accounts) {
      final List<Transaction> transactions = Data().accounts.getTransactions(account).toList()
        ..sort(
          (Transaction left, Transaction right) {
            final DateTime leftDate = left.fieldDateTime.value ?? DateTime.fromMillisecondsSinceEpoch(0);
            final DateTime rightDate = right.fieldDateTime.value ?? DateTime.fromMillisecondsSinceEpoch(0);
            return leftDate.compareTo(rightDate);
          },
        );

      final bool isTruncated = transactions.length > _maxTransactionsPerAccountInPrompt;
      final List<Transaction> includedTransactions = isTruncated
          ? transactions.sublist(transactions.length - _maxTransactionsPerAccountInPrompt)
          : transactions;

      final List<Map<String, Object?>> transactionsPayload = includedTransactions
          .map(
            (Transaction transaction) => <String, Object?>{
              'transaction_id': transaction.uniqueId,
              'date': transaction.dateTimeAsString,
              'amount': transaction.fieldAmount.value.asDouble(),
              'amount_display': transaction.amountAsString,
              'is_transfer': transaction.isTransfer,
              'payee_name': transaction.payeeName,
              'category_name': transaction.categoryName,
              'memo': transaction.fieldMemo.value,
              'description': transaction.oneLinePayeeAndDescription,
            },
          )
          .toList();

      accountsPayload.add(
        <String, Object>{
          'account_id': account.uniqueId,
          'account_name': account.fieldName.value,
          'account_type': getTypeAsText(account.fieldType.value),
          'total_transactions': transactions.length,
          'included_transactions': transactionsPayload.length,
          'is_truncated': isTruncated,
          'transactions': transactionsPayload,
        },
      );
    }

    final Map<String, Object> contextPayload = <String, Object>{
      'context_version': _promptContextVersion,
      'accounts_count': accountsPayload.length,
      'accounts': accountsPayload,
    };

    // Compact JSON: indentation made the prompt ~25% more tokens, and so slower to read.
    return jsonEncode(contextPayload);
  }

  /// Appends a message to chat history and triggers UI update.
  ///
  /// [text] is the message text to append.
  /// [source] is the source of the message (user or AI).
  /// [payload] is the payload sent to Ollama, if any.
  void _appendChatHistory(
    String text,
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
      final OllamaStatus status = await OllamaService.checkOllamaStatus();
      _isOllamaInstalled = status.isInstalled;
      _isOllamaRunning = status.isRunning;
    } catch (e) {
      AppLogger.warning(
        module: 'ai_view',
        operation: '_checkOllamaStatus',
        message: e.toString(),
      );
      _isOllamaInstalled = false;
      _isOllamaRunning = false;
    }

    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  /// Builds the chat list view including history and processing indicator.
  Widget _chatListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(SizeForPadding.large),
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
}
