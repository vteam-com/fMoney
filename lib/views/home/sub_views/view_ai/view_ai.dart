import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:money/core/widgets/box.dart';
import 'package:money/core/widgets/gaps.dart';
import 'package:money/core/widgets/my_segment.dart';
import 'package:money/core/widgets/text_title.dart';
import 'package:money/core/widgets/working.dart';
import 'package:money/data/models/money_objects/transactions/transaction.dart';
import 'package:money/data/storage/data/data.dart';
import 'package:money/views/home/sub_views/view.dart';
import 'package:url_launcher/url_launcher.dart';

enum MessageType { user, ai }

class ChatMessage {
  ChatMessage({
    required this.message,
    required this.type,
    required this.timestamp,
    this.isExpanded = false,
    this.contextMode = 0,
    this.fullPrompt,
  });

  final String message;
  final MessageType type;
  final DateTime timestamp;
  bool isExpanded;
  final int contextMode;
  final String? fullPrompt;
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
  bool _cancelled = false;
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
                                if (message.fullPrompt != null) ...<Widget>[
                                  gapSmall(),
                                  IconButton(
                                    onPressed: () {
                                      _showPromptPopup(message.fullPrompt!);
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
                          const WorkingIndicator(size: 10),
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

    String contextPrompt = '';
    if (_contextMode == 1) {
      contextPrompt = _getDataAsCSV();
    }

    // Add user message to chat history
    setState(() {
      _chatHistory.add(
        ChatMessage(
          message: text,
          type: MessageType.user,
          timestamp: DateTime.now(),
          contextMode: _contextMode,
          fullPrompt: _contextMode == 1 ? '$text\n\n$contextPrompt' : null,
        ),
      );
      _isProcessingPrompt = true;
    });

    // Clear input field
    _textController.clear();

    // Set 20-second timeout
    _timeoutTimer = Timer(const Duration(seconds: 120), () {
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
        fullPrompt = 'USER QUESTION: $text\n\n$contextPrompt';
      }

      // Ensure the prompt is valid UTF-8
      fullPrompt = utf8.decode(utf8.encode(fullPrompt));

      // Send prompt to Ollama via HTTP API
      final Uri generateUrl = Uri.parse('http://localhost:11434/api/generate');
      final HttpClient client = HttpClient();

      // Create the HTTP request
      final HttpClientRequest request = await client.postUrl(generateUrl);

      // Prepare the JSON payload
      final Map<String, dynamic> payload = <String, dynamic>{
        'model': 'deepseek-r1:14b', //'gpt-oss:20b',
        'prompt': fullPrompt,
        'stream': false, // Set to false for simplicity, response comes back all at once
      };

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
            ),
          );
        });
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
          ),
        );
      });
    }
  }
    _cancelled = false;
  }



  void _showPromptPopup(final String fullPrompt) {
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
                fullPrompt,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          actions: <Widget>[
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

  String _getDataAsCSV() {
    final StringBuffer fullCsv = StringBuffer();

    // Header
    // fullCsv.writeln('ACCOUNTS');
    // try {
    //   fullCsv.writeln(Data().accounts.toCSV());
    // } catch (e) {
    //   fullCsv.writeln('Error loading accounts data');
    // }
    // fullCsv.writeln();
    // fullCsv.writeln('CATEGORIES');
    // try {
    //   fullCsv.writeln(Data().categories.toCSV());
    // } catch (e) {
    //   fullCsv.writeln('Error loading categories data');
    // }
    // fullCsv.writeln();
    // fullCsv.writeln('PAYEES');
    // try {
    //   fullCsv.writeln(Data().payees.toCSV());
    // } catch (e) {
    //   fullCsv.writeln('Error loading payees data');
    // }
    // fullCsv.writeln();
    // fullCsv.writeln('TRANSACTIONS');
    try {
      String csvString = '';

      for (final Transaction transaction in Data().transactions.iterableList()) {
        csvString +=
            '"${transaction.accountName}"\t"${transaction.dateTimeAsString}"\t"${transaction.amountAsString}"'
            '\n';
      }

      fullCsv.writeln(csvString);
    } catch (e) {
      fullCsv.writeln('Error loading transactions data');
    }
    // fullCsv.writeln();
    // fullCsv.writeln('INVESTMENTS');
    // try {
    //   fullCsv.writeln(Data().investments.toCSV());
    // } catch (e) {
    //   fullCsv.writeln('Error loading investments data');
    // }
    // fullCsv.writeln();
    // fullCsv.writeln('SECURITIES');
    // try {
    //   fullCsv.writeln(Data().securities.toCSV());
    // } catch (e) {
    //   fullCsv.writeln('Error loading securities data');
    // }

    // Clean up the CSV string (remove carriage returns, nulls, and UTF-8 BOM)
    final String finacialData = fullCsv
        .toString()
        .replaceAll('\r', '')
        .replaceAll('\u0000', '')
        .replaceAll('\uFEFF', '');

    // Updated prompt to clarify CSV includes headers and is not code/numeric input
    return 'You are an experienced financial analyst AI, not a programmer or developer. '
        'You analyze transactions data and provide insights, summaries, and answers using clear, natural English sentences only. '
        'You must NEVER write, mention, or generate any kind of code (including Python, VBA, SQL, or shell scripts)". '
        'When the user asks a question such as "find the largest transaction amount", you must read the data, find the correct value, and respond like a financial report: '
        'If multiple relevant insights exist, summarize them succinctly. '
        '```Tab delimited rows\n'
        '$finacialData'
        '```\n';
  }
}
