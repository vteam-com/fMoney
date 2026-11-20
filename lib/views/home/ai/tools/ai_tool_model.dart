// ignore: fcheck_hardcoded_strings
// Tool names, descriptions and results are written for the AI model, in English; the user never sees them.

/// JSON-schema type of a whole-number argument.
const String _typeInteger = 'integer';

/// JSON-schema type of a decimal argument.
const String _typeNumber = 'number';

/// JSON-schema type of a text argument.
const String _typeString = 'string';

/// JSON-schema type of a true/false argument.
const String _typeBoolean = 'boolean';

/// JSON-schema type of a list argument.
const String _typeArray = 'array';

/// JSON-schema type of the whole argument object.
const String _typeObject = 'object';

/// What a tool runs: it receives the model's arguments and returns a JSON-encodable result.
typedef AiToolHandler = Future<Object?> Function(Map<String, dynamic> args);

/// A function the AI model can call: its name, what it does, its arguments, and the code that runs it.
class AiTool {
  /// Creates a tool the model sees as [name] with [description], taking [parameters] ([required] ones must be given).
  const AiTool({
    required this.name,
    required this.description,
    required this.parameters,
    required this.run,
    this.required = const <String>[],
  });

  /// Tells the model what the tool does and when to use it.
  final String description;

  /// Name the model calls the tool by.
  final String name;

  /// JSON-schema description of each argument, keyed by argument name.
  final Map<String, Map<String, Object>> parameters;

  /// Names of the arguments the model must give.
  final List<String> required;

  /// Runs the tool on the model's arguments.
  final AiToolHandler run;

  /// Returns this tool in the shape Ollama's chat API expects in its `tools` list.
  Map<String, dynamic> toOllamaJson() {
    return <String, dynamic>{
      'type': 'function',
      'function': <String, dynamic>{
        'name': name,
        'description': description,
        'parameters': <String, dynamic>{
          'type': _typeObject,
          'properties': parameters,
          'required': required,
        },
      },
    };
  }
}

/// Returns the schema of a whole-number argument described by [description].
Map<String, Object> aiIntParam(String description) => <String, Object>{
  'type': _typeInteger,
  'description': description,
};

/// Returns the schema of a decimal argument described by [description].
Map<String, Object> aiNumberParam(String description) => <String, Object>{
  'type': _typeNumber,
  'description': description,
};

/// Returns the schema of a text argument described by [description], limited to [values] when given.
Map<String, Object> aiStringParam(String description, {List<String> values = const <String>[]}) => <String, Object>{
  'type': _typeString,
  'description': description,
  if (values.isNotEmpty) 'enum': values,
};

/// Returns the schema of a true/false argument described by [description].
Map<String, Object> aiBoolParam(String description) => <String, Object>{
  'type': _typeBoolean,
  'description': description,
};

/// Returns the schema of a list-of-whole-numbers argument described by [description].
Map<String, Object> aiIntListParam(String description) => <String, Object>{
  'type': _typeArray,
  'items': <String, String>{'type': _typeInteger},
  'description': description,
};
