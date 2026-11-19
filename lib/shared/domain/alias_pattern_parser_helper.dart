import 'package:money/shared/domain/alias_entity.dart';

/// Opens a group.
const String _groupOpen = '(';

/// Closes a group.
const String _groupClose = ')';

/// Follows [_groupOpen] in a non-capturing group.
const String _nonCapturing = '?:';

/// Follows [_groupOpen] in the other special groups (lookarounds, named groups); also the lazy mark.
const String _question = '?';

/// Separates alternatives.
const String _alternative = '|';

/// Opens a character set.
const String _setOpen = '[';

/// Closes a character set.
const String _setClose = ']';

/// Negates a character set when it comes first in it.
const String _caret = '^';

/// Any character.
const String _dot = '.';

/// The end of the text.
const String _dollar = r'$';

/// Starts an escape.
const String _backslash = r'\';

/// Escaped letter for a digit.
const String _digitClass = 'd';

/// Escaped letter for a whitespace character.
const String _spaceClass = 's';

/// Escaped letter for a letter, digit or underscore.
const String _wordClass = 'w';

/// Repeats zero or more times.
const String _star = '*';

/// Repeats one or more times.
const String _plus = '+';

/// Name of the [_braces] group holding the fewest repetitions.
const String _minGroup = 'min';

/// Name of the [_braces] group holding the most repetitions.
const String _maxGroup = 'max';

/// A `{min}`, `{min,}` or `{min,max}` repetition.
final RegExp _braces = RegExp('\\{(?<$_minGroup>\\d+)(?:,(?<$_maxGroup>\\d*))?\\}');

/// A letter or a digit.
final RegExp _alphanumeric = RegExp('[A-Za-z0-9]');

/// What one part of an alias regex matches.
enum AliasPatternPartKind {
  /// The literal text in [AliasPatternPart.text].
  text,

  /// Any character (`.`).
  anyCharacter,

  /// A digit (`\d`).
  digit,

  /// A whitespace character (`\s`).
  space,

  /// A letter, digit or underscore (`\w`).
  wordCharacter,

  /// One of the characters listed in [AliasPatternPart.text] (`[...]`).
  characterSet,

  /// One character not listed in [AliasPatternPart.text] (`[^...]`).
  notCharacterSet,

  /// The start of the text (`^`).
  start,

  /// The end of the text (`$`).
  end,

  /// One of the sequences in [AliasPatternPart.choices]: a group, or alternatives joined by `|`.
  choices,

  /// Anything else (lookarounds, other escapes); its source is in [AliasPatternPart.text].
  other,
}

/// One part of an alias regex: what it matches ([kind]) and how many times ([min] to [max]).
class AliasPatternPart {
  /// Creates a part that matches [kind] once unless [min] and [max] say otherwise.
  const AliasPatternPart(
    this.kind, {
    this.text = '',
    this.choices = const <List<AliasPatternPart>>[],
    this.min = 1,
    this.max = 1,
  });

  /// The sequences an [AliasPatternPartKind.choices] part chooses from.
  final List<List<AliasPatternPart>> choices;

  /// What this part matches.
  final AliasPatternPartKind kind;

  /// Most times this part repeats; null for no limit.
  final int? max;

  /// Fewest times this part repeats.
  final int min;

  /// The literal text, the characters of a set, or the source of an [AliasPatternPartKind.other] part.
  final String text;

  /// True when this part matches exactly once.
  bool get isOnce => min == 1 && max == 1;

  /// Returns this part repeated [times].
  AliasPatternPart repeated(({int min, int? max}) times) =>
      AliasPatternPart(kind, text: text, choices: choices, min: times.min, max: times.max);
}

/// An alias regex split into its [parts], and whether it ignores case.
typedef AliasPatternParts = ({bool ignoreCase, List<AliasPatternPart> parts});

/// Splits the alias regex [pattern] into its parts; returns null when it is not a valid regex.
AliasPatternParts? parseAliasPattern(String pattern) {
  if (tryParseAliasRegex(pattern) == null) {
    return null;
  }
  final ({bool ignoreCase, String source}) split = splitAliasCaseOption(pattern);
  final List<List<AliasPatternPart>> choices = _AliasPatternReader(split.source).readChoices();
  return (
    ignoreCase: split.ignoreCase,
    parts: choices.length == 1
        ? choices.first
        : <AliasPatternPart>[AliasPatternPart(AliasPatternPartKind.choices, choices: choices)],
  );
}

/// Returns the texts [parts] match when they are plain text or a choice of plain texts, else null.
List<String>? literalTextsOf(List<AliasPatternPart> parts) {
  final bool isChoice = parts.length == 1 && parts.first.kind == AliasPatternPartKind.choices && parts.first.isOnce;
  final List<String?> texts = isChoice
      ? parts.first.choices.map(_literalTextOf).toList()
      : <String?>[_literalTextOf(parts)];
  return texts.contains(null) ? null : texts.whereType<String>().toList();
}

/// Returns the text [parts] match when they are one plain text, else null.
String? _literalTextOf(List<AliasPatternPart> parts) =>
    parts.length == 1 && parts.first.kind == AliasPatternPartKind.text && parts.first.isOnce ? parts.first.text : null;

/// Reads a valid regex source one part at a time.
class _AliasPatternReader {
  _AliasPatternReader(this._source);

  int _index = 0;

  final String _source;

  /// Reads the alternatives up to the end, or up to the parenthesis that closes the current group.
  List<List<AliasPatternPart>> readChoices() {
    final List<List<AliasPatternPart>> choices = <List<AliasPatternPart>>[_readSequence()];
    while (_isAt(_alternative)) {
      _index++;
      choices.add(_readSequence());
    }
    return choices;
  }

  /// True when there is more source to read.
  bool get _hasMore => _index < _source.length;

  /// Appends [part] to [parts], joining it to the literal text before it.
  static void _addPart(List<AliasPatternPart> parts, AliasPatternPart part) {
    final bool joinsText =
        parts.isNotEmpty &&
        part.kind == AliasPatternPartKind.text &&
        part.isOnce &&
        parts.last.kind == AliasPatternPartKind.text &&
        parts.last.isOnce;
    if (joinsText) {
      parts.last = AliasPatternPart(AliasPatternPartKind.text, text: parts.last.text + part.text);
    } else {
      parts.add(part);
    }
  }

  /// True when the source continues with [token].
  bool _isAt(String token) => _source.startsWith(token, _index);

  /// Reads one character, escape, set or group.
  AliasPatternPart _readAtom() {
    final int start = _index;
    final String char = _source[_index++];
    switch (char) {
      case _groupOpen:
        if (_isAt(_nonCapturing)) {
          _index += _nonCapturing.length;
        } else if (_isAt(_question)) {
          return _readOtherGroup(start);
        }
        final List<List<AliasPatternPart>> choices = readChoices();
        _index++; // the closing parenthesis
        return AliasPatternPart(AliasPatternPartKind.choices, choices: choices);
      case _setOpen:
        final bool negated = _isAt(_caret);
        if (negated) {
          _index++;
        }
        final int setStart = _index;
        _skipToSetEnd();
        return AliasPatternPart(
          negated ? AliasPatternPartKind.notCharacterSet : AliasPatternPartKind.characterSet,
          text: _source.substring(setStart, _index - _setClose.length),
        );
      case _dot:
        return const AliasPatternPart(AliasPatternPartKind.anyCharacter);
      case _caret:
        return const AliasPatternPart(AliasPatternPartKind.start);
      case _dollar:
        return const AliasPatternPart(AliasPatternPartKind.end);
      case _backslash:
        final String escaped = _source[_index++];
        return switch (escaped) {
          _digitClass => const AliasPatternPart(AliasPatternPartKind.digit),
          _spaceClass => const AliasPatternPart(AliasPatternPartKind.space),
          _wordClass => const AliasPatternPart(AliasPatternPartKind.wordCharacter),
          _ when _alphanumeric.hasMatch(escaped) => AliasPatternPart(
            AliasPatternPartKind.other,
            text: _source.substring(start, _index),
          ),
          _ => AliasPatternPart(AliasPatternPartKind.text, text: escaped),
        };
      default:
        return AliasPatternPart(AliasPatternPartKind.text, text: char);
    }
  }

  /// Reads a lookaround or named group, which starts at [start], as one [AliasPatternPartKind.other] part.
  AliasPatternPart _readOtherGroup(int start) {
    int depth = 1;
    while (_hasMore && depth > 0) {
      final String char = _source[_index++];
      if (char == _backslash) {
        _index++;
      } else if (char == _setOpen) {
        _skipToSetEnd();
      } else if (char == _groupOpen) {
        depth++;
      } else if (char == _groupClose) {
        depth--;
      }
    }
    return AliasPatternPart(AliasPatternPartKind.other, text: _source.substring(start, _index));
  }

  /// Reads how many times the part before repeats, or returns null when it appears once.
  ({int min, int? max})? _readQuantifier() {
    ({int min, int? max})? times;
    if (_isAt(_star)) {
      times = (min: 0, max: null);
    } else if (_isAt(_plus)) {
      times = (min: 1, max: null);
    } else if (_isAt(_question)) {
      times = (min: 0, max: 1);
    }
    if (times != null) {
      _index++;
    } else {
      final RegExpMatch? match = _braces.matchAsPrefix(_source, _index) as RegExpMatch?;
      if (match == null) {
        return null;
      }
      _index = match.end;
      final int min = int.parse(match.namedGroup(_minGroup)!);
      // no comma: exactly min; a comma with nothing after it: no limit
      final String? upTo = match.namedGroup(_maxGroup);
      times = (min: min, max: upTo == null ? min : int.tryParse(upTo));
    }
    // a lazy repetition matches the same texts
    if (_isAt(_question)) {
      _index++;
    }
    return times;
  }

  /// Reads parts up to the end, a `|`, or the parenthesis that closes the current group.
  List<AliasPatternPart> _readSequence() {
    final List<AliasPatternPart> parts = <AliasPatternPart>[];
    while (_hasMore && !_isAt(_alternative) && !_isAt(_groupClose)) {
      final AliasPatternPart atom = _readAtom();
      final ({int min, int? max})? times = _readQuantifier();
      final AliasPatternPart part = times == null ? atom : atom.repeated(times);
      // a plain group adds nothing to explain: its parts read as if it were not there
      if (part.kind == AliasPatternPartKind.choices && part.isOnce && part.choices.length == 1) {
        for (final AliasPatternPart inner in part.choices.first) {
          _addPart(parts, inner);
        }
      } else {
        _addPart(parts, part);
      }
    }
    return parts;
  }

  /// Moves past the `]` that closes the character set being read.
  void _skipToSetEnd() {
    while (_hasMore) {
      final String char = _source[_index++];
      if (char == _backslash) {
        _index++;
      } else if (char == _setClose) {
        return;
      }
    }
  }
}
