import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:money/views/home/ai/tools/ai_tool_chat_service.dart';
import 'package:money/views/home/ai/tools/ai_tool_model.dart';

/// Turns the fake model takes before giving up calling tools in the max-turns test.
const int _maxTurns = 8;

/// A chat reply from the model with [content] and the given [toolCalls].
Map<String, dynamic> _reply(String content, {List<Map<String, dynamic>> toolCalls = const <Map<String, dynamic>>[]}) {
  return <String, dynamic>{
    'message': <String, dynamic>{
      'role': 'assistant',
      'content': content,
      if (toolCalls.isNotEmpty) 'tool_calls': toolCalls,
    },
    'prompt_eval_count': 42,
  };
}

/// A structured call of tool [name] with [arguments].
Map<String, dynamic> _call(String name, Map<String, dynamic> arguments) => <String, dynamic>{
  'function': <String, dynamic>{'name': name, 'arguments': arguments},
};

/// A tool named echo that returns its arguments and records them in [received].
AiTool _echoTool(List<Map<String, dynamic>> received) => AiTool(
  name: 'echo',
  description: 'Returns its arguments.',
  parameters: <String, Map<String, Object>>{'n': aiIntParam('A number.')},
  run: (Map<String, dynamic> args) async {
    received.add(args);
    return args;
  },
);

/// Returns a fake sender that answers with [replies] in turn and records the tools offered each turn in [toolsSent].
AiChatSender _scripted(List<Map<String, dynamic>> replies, List<int> toolsSent) {
  int turn = 0;
  return ({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
    required int contextWindow,
  }) async {
    toolsSent.add(tools.length);
    return replies[turn++];
  };
}

/// Returns the conversation the tests start from.
List<Map<String, dynamic>> _question() => <Map<String, dynamic>>[
  <String, dynamic>{'role': 'user', 'content': 'question'},
];

void main() {
  test('runs each tool the model calls, sends the result back, and returns the answer', () async {
    final List<Map<String, dynamic>> received = <Map<String, dynamic>>[];
    final List<int> toolsSent = <int>[];
    final List<Map<String, dynamic>> messages = _question();

    final AiToolChatAnswer? answer = await AiToolChatService(
      tools: <AiTool>[_echoTool(received)],
      isCancelled: () => false,
      send: _scripted(<Map<String, dynamic>>[
        _reply(
          '',
          toolCalls: <Map<String, dynamic>>[
            _call('echo', <String, dynamic>{'n': 7}),
          ],
        ),
        _reply('  The answer.  '),
      ], toolsSent),
    ).answer(messages);

    expect(answer?.text, 'The answer.');
    expect(answer?.promptTokens, 42);
    expect(received, <Map<String, dynamic>>[
      <String, dynamic>{'n': 7},
    ]);
    final Map<String, dynamic> toolResult = messages.firstWhere((Map<String, dynamic> m) => m['role'] == 'tool');
    expect(toolResult['tool_name'], 'echo');
    expect(jsonDecode(toolResult['content'] as String), <String, dynamic>{'n': 7});
    expect(toolsSent, <int>[1, 1]);
  });

  test('runs tool calls the model wrote as text, reading numbers as numbers', () async {
    final List<Map<String, dynamic>> received = <Map<String, dynamic>>[];
    final List<Map<String, dynamic>> messages = _question();

    await AiToolChatService(
      tools: <AiTool>[_echoTool(received)],
      isCancelled: () => false,
      send: _scripted(<Map<String, dynamic>>[
        _reply(
          'Let me look.\n\n<function=echo>\n<parameter=n>\n3\n</parameter>\n<parameter=text>\ncondo\n</parameter>\n</function>\n</tool_call>',
        ),
        _reply('Done.'),
      ], <int>[]),
    ).answer(messages);

    expect(received, <Map<String, dynamic>>[
      <String, dynamic>{'n': 3, 'text': 'condo'},
    ]);
    expect(messages[1]['content'], 'Let me look.');
  });

  test('tells the model about unknown tools and tool errors instead of failing', () async {
    final AiTool failing = AiTool(
      name: 'failing',
      description: 'Always fails.',
      parameters: <String, Map<String, Object>>{},
      run: (Map<String, dynamic> _) async => throw ArgumentError('No transaction with id 9.'),
    );
    final AiTool huge = AiTool(
      name: 'huge',
      description: 'Returns too much.',
      parameters: <String, Map<String, Object>>{},
      run: (Map<String, dynamic> _) async => 'x' * 20000,
    );
    final List<Map<String, dynamic>> messages = _question();

    await AiToolChatService(
      tools: <AiTool>[failing, huge],
      isCancelled: () => false,
      send: _scripted(<Map<String, dynamic>>[
        _reply(
          '',
          toolCalls: <Map<String, dynamic>>[
            _call('missing', <String, dynamic>{}),
            _call('failing', <String, dynamic>{}),
            _call('huge', <String, dynamic>{}),
          ],
        ),
        _reply('Sorry.'),
      ], <int>[]),
    ).answer(messages);

    final List<String> results = messages
        .where((Map<String, dynamic> m) => m['role'] == 'tool')
        .map(
          (Map<String, dynamic> m) => (jsonDecode(m['content'] as String) as Map<String, dynamic>)['error'] as String,
        )
        .toList();
    expect(results[0], contains('Unknown tool "missing"'));
    expect(results[1], 'No transaction with id 9.');
    expect(results[2], contains('too large'));
  });

  test('returns null and runs no tool once cancelled', () async {
    final List<Map<String, dynamic>> received = <Map<String, dynamic>>[];

    final AiToolChatAnswer? answer = await AiToolChatService(
      tools: <AiTool>[_echoTool(received)],
      isCancelled: () => true,
      send: _scripted(<Map<String, dynamic>>[
        _reply(
          '',
          toolCalls: <Map<String, dynamic>>[
            _call('echo', <String, dynamic>{'n': 1}),
          ],
        ),
      ], <int>[]),
    ).answer(_question());

    expect(answer, isNull);
    expect(received, isEmpty);
  });

  test('sends the last turn without tools so the model has to answer', () async {
    final List<int> toolsSent = <int>[];
    final List<Map<String, dynamic>> replies = <Map<String, dynamic>>[
      for (int i = 1; i < _maxTurns; i++)
        _reply(
          '',
          toolCalls: <Map<String, dynamic>>[
            _call('echo', <String, dynamic>{'n': i}),
          ],
        ),
      _reply('Final.'),
    ];

    final AiToolChatAnswer? answer = await AiToolChatService(
      tools: <AiTool>[_echoTool(<Map<String, dynamic>>[])],
      isCancelled: () => false,
      send: _scripted(replies, toolsSent),
    ).answer(_question());

    expect(answer?.text, 'Final.');
    expect(toolsSent.length, _maxTurns);
    expect(toolsSent.last, 0);
  });
}
