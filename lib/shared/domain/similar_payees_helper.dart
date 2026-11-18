import 'dart:math';

import 'package:money/helpers/list_helper.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/payee_entity.dart';

/// Shortest compacted name worth comparing; shorter ones (like "BP") are too ambiguous.
const int _minComparableLength = 3;

/// Leading characters two compacted names must share to look like the same merchant.
const int _sharedPrefixLength = 5;

/// Starts a case-insensitive, non-capturing regex group (MyMoney.Net style, see [tryParseAliasRegex]).
const String _caseInsensitiveGroupStart = '(?i)(?:';

/// Separates the alternatives of a regex group.
const String _alternative = '|';

/// Closes a regex group.
const String _groupEnd = ')';

/// Everything that is not an uppercase letter or a digit.
final RegExp _nonAlphanumeric = RegExp('[^A-Z0-9]');

/// Returns [name] uppercased without spaces or punctuation, so "AT&T*BILL" becomes "ATTBILL".
String compactPayeeName(String name) => name.toUpperCase().replaceAll(_nonAlphanumeric, '');

/// True when [a] and [b], once compacted, share their first five characters (or all of the shorter one).
bool arePayeeNamesSimilar(String a, String b) {
  final String compactA = compactPayeeName(a);
  final String compactB = compactPayeeName(b);
  final int shorterLength = min(compactA.length, compactB.length);
  if (shorterLength < _minComparableLength) {
    return false;
  }
  final int length = min(shorterLength, _sharedPrefixLength);
  return compactA.substring(0, length) == compactB.substring(0, length);
}

/// Returns the [candidates] whose names look like [payee]'s and that no alias in [aliases] already maps,
/// sorted by name.
List<Payee> findSimilarPayees(Payee payee, Iterable<Payee> candidates, Iterable<Alias> aliases) {
  return candidates
      .where(
        (Payee candidate) =>
            candidate.uniqueId != payee.uniqueId &&
            arePayeeNamesSimilar(payee.fieldName.value, candidate.fieldName.value) &&
            !aliases.any((Alias alias) => alias.isMatch(candidate.fieldName.value)),
      )
      .toList()
    ..sort((Payee a, Payee b) => sortByString(a.fieldName.value, b.fieldName.value, true));
}

/// Builds a case-insensitive regex alias pattern that matches exactly any of [names].
String aliasPatternForNames(Iterable<String> names) =>
    _caseInsensitiveGroupStart + names.map(RegExp.escape).join(_alternative) + _groupEnd;
