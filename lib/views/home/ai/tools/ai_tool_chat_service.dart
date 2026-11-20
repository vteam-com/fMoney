// ignore: fcheck_hardcoded_strings
// Tool names, descriptions and results are written for the AI model, in English; the user never sees them.
import 'dart:convert';

import 'package:money/data/services/ollama_service.dart';
import 'package:money/views/home/ai/tools/ai_tool_model.dart';

/// Most model turns in one answer; the last one is sent without tools, so the model must answer.
const int _maxModelTurns = 8;

/// Context window for tool conversations. The instructions, tool list, recent messages and capped tool
/// results fit in it, and keeping one size for every turn keeps the model loaded between turns.
const int aiToolChatContextTokens = 32768;

/// Longest tool result passed to the model, in characters (about 5K tokens).
const int _maxToolResultChars = 16000;

/// Key of the model's message in a chat reply.
const String _keyMessage = 'message';

/// Key of the tool calls in a model message.
const String _keyToolCalls = 'tool_calls';

/// Key of the called function in a tool call.
const String _keyFunction = 'function';

/// Key of the text of a message.
const String _keyContent = 'content';

/// Key of the prompt size, in tokens, in a chat reply.
const String _keyPromptEvalCount = 'prompt_eval_count';

/// A tool call written as text, as qwen3-coder does when it skips its `<tool_call>` tag, so Ollama
/// leaves it in the content: `<function=name><parameter=key>value</parameter>...</function>`.
final RegExp _textToolCall = RegExp(r'<function=([\w.-]+)>(.*?)</function>', dotAll: true);

/// One argument of a [_textToolCall].
final RegExp _textToolArgument = RegExp(r'<parameter=([\w.-]+)>(.*?)</parameter>', dotAll: true);

/// Match group of the name in a [_textToolCall] or [_textToolArgument].
const int _groupName = 1;

/// Match group of the body (arguments or value) in a [_textToolCall] or [_textToolArgument].
const int _groupBody = 2;

/// Tags left around a [_textToolCall], removed from the text kept as the model's message.
final RegExp _textToolCallTags = RegExp('</?tool_call>');

/// Sends chat [messages] with the [tools] the model may call and returns the reply in the shape of
/// Ollama's chat API; [OllamaService.sendChat] in the app, a fake in tests.
typedef AiChatSender = Future<Map<String, dynamic>> Function({
  required List<Map<String, dynamic>> messages,
  required List<Map<String, dynamic>> tools,
  required int contextWindow,
});

/// The model's final answer: its [text] and the size in tokens of the last prompt.
typedef AiToolChatAnswer = ({String text, int promptTokens});

/// Runs a tool conversation: sends the messages, runs each tool the model calls, sends the results
/// back, and repeats until the model answers.
class AiToolChatService {
  /// Creates a conversation that offers [tools], sends with [send], and stops once [isCancelled].
  AiToolChatService({
    required List<AiTool> tools,
    required this._isCancelled,
    this._send = OllamaService.sendChat,
  }) : _toolsByName = <String, AiTool>{for (final AiTool tool in tools) tool.name: tool};

  /// Returns true once the user cancelled or left, so no further turn or tool runs.
  final bool Function() _isCancelled;

  /// Sends one turn to the model.
  final AiChatSender _send;

  /// The tools offered, by name.
  final Map<String, AiTool> _toolsByName;

  /// Runs the conversation [messages] (instructions, recent messages, question) until the model
  /// answers, appending every model turn and tool result to [messages]. Returns null when cancelled.
  Future<AiToolChatAnswer?> answer(List<Map<String, dynamic>> messages) async {
    final List<Map<String, dynamic>> toolsJson = _toolsByName.values.map((AiTool tool) => tool.toOllamaJson()).toList();
    Map<String, dynamic> reply = <String, dynamic>{};
    for (int turn = 1; turn <= _maxModelTurns; turn++) {
      reply = await _send(
        messages: messages,
        tools: turn < _maxModelTurns ? toolsJson : <Map<String, dynamic>>[],
        contextWindow: aiToolChatContextTokens,
      );
      if (_isCancelled()) {
        return null;
      }
      final Map<String, dynamic> message = _withTextToolCallsParsed(
        (reply[_keyMessage] as Map<String, dynamic>?) ?? <String, dynamic>{},
      );
      messages.add(message);
      final List<dynamic> calls = (message[_keyToolCalls] as List<dynamic>?) ?? <dynamic>[];
      if (calls.isEmpty) {
        break;
      }
      for (final dynamic call in calls) {
        final Map<String, dynamic> function =
            ((call as Map<String, dynamic>)[_keyFunction] as Map<String, dynamic>?) ?? <String, dynamic>{};
        final String name = function['name'] as String? ?? '';
        final String result = await _runTool(name, function['arguments']);
        if (_isCancelled()) {
          return null;
        }
        messages.add(<String, dynamic>{'role': 'tool', 'tool_name': name, _keyContent: result});
      }
    }
    final Map<String, dynamic> last = messages.last;
    return (
      text: (last[_keyContent] as String? ?? '').replaceAll(_textToolCallTags, '').trim(),
      promptTokens: reply[_keyPromptEvalCount] as int? ?? 0,
    );
  }

  /// Returns [message] with the tool calls it wrote as text (see [_textToolCall]) moved into its
  /// `tool_calls` and out of its content; [message] itself when it has real tool calls or none in text.
  static Map<String, dynamic> _withTextToolCallsParsed(Map<String, dynamic> message) {
    final String content = message[_keyContent] as String? ?? '';
    final List<RegExpMatch> calls = _textToolCall.allMatches(content).toList();
    if (calls.isEmpty || ((message[_keyToolCalls] as List<dynamic>?)?.isNotEmpty ?? false)) {
      return message;
    }
    return <String, dynamic>{
      ...message,
      _keyContent: content.substring(0, calls.first.start).replaceAll(_textToolCallTags, '').trim(),
      _keyToolCalls: calls
          .map(
            (RegExpMatch call) => <String, dynamic>{
              _keyFunction: <String, dynamic>{
                'name': call[_groupName],
                'arguments': <String, dynamic>{
                  for (final RegExpMatch argument in _textToolArgument.allMatches(call[_groupBody]!))
                    argument[_groupName]!: _textArgumentValue(argument[_groupBody]!.trim()),
                },
              },
            },
          )
          .toList(),
    };
  }

  /// Returns [text] read as JSON when it is (a number, list, boolean...), else the text itself.
  static Object? _textArgumentValue(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return text;
    }
  }

  /// Runs tool [name] on [rawArgs] (an object, or JSON text from some models) and returns its result as
  /// JSON; failures come back as an `error` the model can read and correct.
  Future<String> _runTool(String name, Object? rawArgs) async {
    final AiTool? tool = _toolsByName[name];
    if (tool == null) {
      return jsonEncode(<String, String>{'error': 'Unknown tool "$name".'});
    }
    try {
      final Map<String, dynamic> args = rawArgs is Map<String, dynamic>
          ? rawArgs
          : (rawArgs is String && rawArgs.isNotEmpty
                ? jsonDecode(rawArgs) as Map<String, dynamic>
                : <String, dynamic>{});
      final String result = jsonEncode(await tool.run(args));
      return result.length <= _maxToolResultChars
          ? result
          : jsonEncode(<String, String>{'error': 'The result is too large; narrow the filters or lower the limit.'});
    } on ArgumentError catch (e) {
      return jsonEncode(<String, String>{'error': '${e.message}'});
    } catch (e) {
      return jsonEncode(<String, String>{'error': e.toString()});
    }
  }
}
