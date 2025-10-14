import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:money/core/widgets/box.dart';
import 'package:money/core/widgets/gaps.dart';
import 'package:money/core/widgets/my_segment.dart';
import 'package:money/core/widgets/text_title.dart';
import 'package:money/core/widgets/working.dart';
import 'package:money/data/storage/data/data.dart';
import 'package:money/views/home/sub_views/view.dart';
import 'package:url_launcher/url_launcher.dart';

enum MessageType { user, ai }

class ChatMessage {
  ChatMessage({required this.message, required this.type, required this.timestamp, this.isExpanded = false});

  final String message;
  final MessageType type;
  final DateTime timestamp;
  bool isExpanded;
}

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
  Timer? _timeoutTimer;
  int _contextMode = 0;
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _chatHistory = <ChatMessage>[];

  @override
  Widget buildHeader([final Widget? child]) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const TextTitle('AI Assistant'),
          IconButton(
            onPressed: () {
              setState(() {
                _chatHistory.clear();
              });
            },
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildViewContent(final Widget child) {
    if (_isChecking) {
      return const Center(child: Text('Checking Ollama status...'));
    }

    if (_isOllamaInstalled && _isOllamaRunning) {
      return _buildChatInterface();
    }
    return _buildInstallPrompt();
  }

  @override
  void initState() {
    super.initState();
    _checkOllamaStatus();
  }

  Widget _buildInstallPrompt() {
    return Center(
      child: Box(
        padding: SizeForPadding.large,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.smart_toy_outlined, size: 64, color: getColorTheme(context).primary),
            gapLarge(),
            const TextTitle('Ollama AI Assistant'),
            gapMedium(),
            const Text(
              'Ollama is required to use the AI assistant. Click below to install it.',
              textAlign: TextAlign.center,
            ),
            gapLarge(),
            ElevatedButton(
              onPressed: _installOllama,
              child: const Text('Install Ollama now'),
            ),
            gapMedium(),
            TextButton(
              onPressed: _checkOllamaStatus,
              child: const Text('Recheck status'),
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
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
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
                          const WorkingIndicator(size: 16),
                          gapSmall(),
                          Text(
                            'Thinking...',
                            style: TextStyle(
                              color: getColorTheme(context).onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
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
                mySegmentSelector(
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
                        onPressed: () => _sendUserPrompt('Suggest budget optimizations'),
                        child: const Text('Budget tips'),
                      ),
                      ElevatedButton(
                        onPressed: () => _sendUserPrompt('Predict future expenses'),
                        child: const Text('Expense predictions'),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: <Widget>[
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
                    gapSmall(),
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

  Future<void> _checkOllamaStatus() async {
    setState(() => _isChecking = true);

    try {
      // Check Ollama status via HTTP request
      final Uri ollamaUrl = Uri.parse('http://localhost:11434/api/tags');
      final HttpClient client = HttpClient();
      final HttpClientRequest request = await client.getUrl(ollamaUrl);
      final HttpClientResponse response = await request.close();

      if (response.statusCode == 200) {
        _isOllamaInstalled = true;
        _isOllamaRunning = true;
      } else {
        _isOllamaInstalled = false;
        _isOllamaRunning = false;
      }
    } catch (e) {
      _isOllamaInstalled = false;
      _isOllamaRunning = false;
      if (kDebugMode) {
        print('Ollama check error: $e');
      }
    }

    setState(() => _isChecking = false);
  }

  Future<void> _installOllama() async {
    // Open Ollama download page
    final Uri url = Uri.parse('https://ollama.com/download');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _sendUserPrompt(final String text) async {
    if (!_isOllamaRunning) {
      setState(() {});
      return;
    }

    // Cancel any existing timeout
    _timeoutTimer?.cancel();

    // Add user message to chat history
    setState(() {
      _chatHistory.add(ChatMessage(message: text, type: MessageType.user, timestamp: DateTime.now()));
      _isProcessingPrompt = true;
    });

    // Clear input field
    _textController.clear();

    // Set 20-second timeout
    _timeoutTimer = Timer(const Duration(seconds: 20), () {
      if (_isProcessingPrompt) {
        setState(() {
          _isProcessingPrompt = false;
          _chatHistory.add(
            ChatMessage(
              message: 'Request timed out. Please try again.',
              type: MessageType.ai,
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    });

    try {
      // Create the full prompt based on context mode
      String fullPrompt = text;
      if (_contextMode == 1) {
        // All data mode
        fullPrompt = 'USER QUESTION: $text\n\n${_getDataAsCSV()}';
      }

      // Send prompt to Ollama via HTTP API
      final Uri generateUrl = Uri.parse('http://localhost:11434/api/generate');
      final HttpClient client = HttpClient();

      // Create the HTTP request
      final HttpClientRequest request = await client.postUrl(generateUrl);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');

      // Prepare the JSON payload
      final Map<String, dynamic> payload = <String, dynamic>{
        'model': 'llama2',
        'prompt': fullPrompt,
        'stream': false, // Set to false for simplicity, response comes back all at once
      };

      request.write(jsonEncode(payload));
      final HttpClientResponse response = await request.close();
      final String responseBody = await response.transform(utf8.decoder).join();

      // Cancel the timeout timer since we got a response
      _timeoutTimer?.cancel();
      _timeoutTimer = null;

      if (response.statusCode == 200) {
        // Parse the JSON response
        final Map<String, dynamic> jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
        final String aiResponse = jsonResponse['response'] as String;
        setState(() {
          _isProcessingPrompt = false;
          _chatHistory.add(
            ChatMessage(
              message: aiResponse.trim(),
              type: MessageType.ai,
              timestamp: DateTime.now(),
            ),
          );
        });
      } else {
        setState(() {
          _isProcessingPrompt = false;
          _chatHistory.add(
            ChatMessage(
              message: 'Error: HTTP ${response.statusCode}',
              type: MessageType.ai,
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    } catch (e) {
      // Cancel the timeout timer since we got an error
      _timeoutTimer?.cancel();
      _timeoutTimer = null;

      setState(() {
        _isProcessingPrompt = false;
        _chatHistory.add(
          ChatMessage(
            message: 'Error: $e',
            type: MessageType.ai,
            timestamp: DateTime.now(),
          ),
        );
      });
    }
  }

  String _getDataAsCSV() {
    final StringBuffer context = StringBuffer();
    context.writeln('You are a financial AI assistant. Here is the user\'s financial data for context:');
    context.writeln();

    // Accounts Summary
    context.writeln('ACCOUNTS:');
    context.writeln(Data().accounts.toCSV());
    context.writeln();

    // Categories Summary
    context.writeln('CATEGORIES:');
    context.writeln(Data().categories.toCSV());

    // Payees Summary
    context.writeln('PAYEES:');
    context.writeln(Data().payees.toCSV());
    context.writeln();

    // Recent Transactions Summary (last 50 transactions)
    context.writeln('RECENT TRANSACTIONS');
    context.writeln(Data().transactions.toCSV());
    context.writeln();

    // Investments Summary
    context.writeln('INVESTMENTS:');
    context.writeln(Data().investments.toCSV());
    context.writeln();

    // Securities Summary
    context.writeln('SECURITIES:');
    context.writeln(Data().securities.toCSV());
    context.writeln();
    return context.toString();
  }
}
