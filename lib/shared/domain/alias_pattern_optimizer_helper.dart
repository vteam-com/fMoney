import 'package:money/shared/domain/alias_entity.dart';

/// Fewest letters and digits a generalized pattern starts with, so it never shrinks to about `.*`.
const int _minSharedAlphanumerics = 3;

/// Regex for any text, or none.
const String _anyText = '.*';

/// Regex for a number.
const String _number = r'\d+';

/// Starts a non-capturing regex group.
const String _groupStart = '(?:';

/// Separates the alternatives of a regex group.
const String _alternative = '|';

/// Closes a regex group.
const String _groupEnd = ')';

/// The first run of letters and digits, which names the merchant in most bank texts.
final RegExp _firstWord = RegExp('[A-Z0-9]+');

/// A letter or a digit.
final RegExp _alphanumeric = RegExp('[A-Za-z0-9]');

/// One or more digits, and nothing else.
final RegExp _digitsOnly = RegExp(r'^[0-9]+$');

/// Builds a case-insensitive alias regex that matches each of [texts] and none of [mustNotMatch].
///
/// Texts that start with the same word become one pattern: their shared start and end, with what
/// differs in between as a number (`\d+`) or any text (`.*`), like `(?i)AMAZON\.COM\*.*`. A group
/// that would match one of [mustNotMatch], or that shares too little, stays as its texts.
String optimizedAliasPattern(Iterable<String> texts, {Iterable<String> mustNotMatch = const <String>[]}) {
  final Map<String, String> textByUppercase = <String, String>{};
  for (final String text in texts.where((String text) => text.trim().isNotEmpty)) {
    textByUppercase.putIfAbsent(text.toUpperCase(), () => text);
  }
  if (textByUppercase.isEmpty) {
    return '';
  }
  final List<String> others = mustNotMatch
      .where((String text) => text.trim().isNotEmpty && !textByUppercase.containsKey(text.toUpperCase()))
      .toList();

  final Map<String, List<String>> groups = <String, List<String>>{};
  for (final String text in textByUppercase.values) {
    final String upper = text.toUpperCase();
    groups.putIfAbsent(_firstWord.firstMatch(upper)?.group(0) ?? upper, () => <String>[]).add(text);
  }
  final String pattern = _joinAlternatives(<String>[
    for (final List<String> group in groups.values) ..._groupAlternatives(group, others),
  ]);

  // Built to match every text; the check guards the MyMoney.Net rule that the first match must cover it
  final RegExp? regex = tryParseAliasRegex(pattern);
  if (regex != null && textByUppercase.values.every((String text) => isWholeAliasMatch(regex, text))) {
    return pattern;
  }
  return _joinAlternatives(textByUppercase.values.map(RegExp.escape).toList());
}

/// Returns the regex alternatives for a [group] of texts that start with the same word: one
/// generalized pattern when it matches none of [others], else each text as is.
List<String> _groupAlternatives(List<String> group, List<String> others) {
  if (group.length > 1) {
    final String? general = _generalize(group);
    final RegExp? regex = general == null ? null : tryParseAliasRegex(aliasCaseInsensitivePrefix + general);
    if (regex != null && !others.any((String other) => isWholeAliasMatch(regex, other))) {
      return <String>[general!];
    }
  }
  return group.map(RegExp.escape).toList();
}

/// Returns a regex for [texts] made of their shared start and end around what differs, or null when
/// their shared start has fewer than [_minSharedAlphanumerics] letters and digits.
String? _generalize(List<String> texts) {
  final String first = texts.first;
  final int shortest = texts.map((String text) => text.length).reduce((int a, int b) => a < b ? a : b);

  int prefix = 0;
  while (prefix < shortest && texts.every((String text) => _sameLetter(text[prefix], first[prefix]))) {
    prefix++;
  }
  int suffix = 0;
  while (suffix < shortest - prefix &&
      texts.every(
        (String text) => _sameLetter(text[text.length - 1 - suffix], first[first.length - 1 - suffix]),
      )) {
    suffix++;
  }
  // A number that varies is generalized whole, not from its middle digits
  while (prefix > 0 && _digitsOnly.hasMatch(first[prefix - 1])) {
    prefix--;
  }
  // A shared end counts from the start of a word: a letter or two in common is chance
  while (suffix > 0 && _alphanumeric.hasMatch(first[first.length - suffix])) {
    suffix--;
  }

  final String head = first.substring(0, prefix);
  if (_alphanumeric.allMatches(head).length < _minSharedAlphanumerics) {
    return null;
  }
  final String tail = first.substring(first.length - suffix);
  final List<String> middles = texts.map((String text) => text.substring(prefix, text.length - suffix)).toList();
  final String middle = middles.every(_digitsOnly.hasMatch) ? _number : _anyText;
  return RegExp.escape(head) + middle + RegExp.escape(tail);
}

/// True when characters [a] and [b] are the same letter, ignoring case.
bool _sameLetter(String a, String b) => a.toUpperCase() == b.toUpperCase();

/// Joins [alternatives] into one case-insensitive pattern, longest first so a shorter alternative
/// that starts the same can't end the match early.
String _joinAlternatives(List<String> alternatives) {
  alternatives.sort((String a, String b) => a.length != b.length ? b.length - a.length : a.compareTo(b));
  return aliasCaseInsensitivePrefix +
      (alternatives.length == 1 ? alternatives.first : _groupStart + alternatives.join(_alternative) + _groupEnd);
}
