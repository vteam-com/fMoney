import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/alias_pattern_optimizer_helper.dart';
import 'package:money/shared/domain/alias_pattern_parser_helper.dart';
import 'package:money/shared/domain/aliases_collection.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/transaction_entity.dart';

/// What Optimize found for an alias: how many transactions it matches now ([currentMatches]), and a
/// better [pattern] with its [matches], or a null [pattern] when there is none.
typedef AliasPatternSuggestion = ({int currentMatches, String? pattern, int matches});

/// Alias patterns built from the transactions in the data.
extension AliasPatternSuggestions on Data {
  /// Builds a case-insensitive alias regex matching all of [texts], as general as it can be without
  /// matching the bank text or payee name of a transaction that [mayMatch] rejects.
  String aliasPatternFor(Iterable<String> texts, bool Function(Transaction transaction) mayMatch) {
    return optimizedAliasPattern(
      texts,
      mustNotMatch: <String>{
        for (final Transaction transaction in aliasableTransactions())
          if (!mayMatch(transaction)) ...Aliases.textsOf(transaction),
      },
    );
  }

  /// Number of transactions [alias] matches, transfers aside (which aliases leave alone).
  int countAliasMatches(Alias alias) =>
      aliasableTransactions().where((Transaction transaction) => Aliases.matchesTransaction(alias, transaction)).length;

  /// Looks for a better pattern for [alias]: one covering what it matches now, the texts it lists and
  /// the bank texts of its payee's transactions, without reaching any other transaction. It is
  /// better when it matches more transactions, or the same ones with a shorter pattern.
  AliasPatternSuggestion suggestAliasPattern(Alias alias) {
    final int payeeId = alias.fieldPayeeId.value;
    final Set<String> texts = <String>{
      ..._textsListedIn(alias),
      for (final Transaction transaction in aliasableTransactions()) ...<String>[
        if (payeeId != -1 && transaction.fieldPayee.value == payeeId) transaction.fieldOriginalPayee.value,
        ...Aliases.textsOf(transaction).where(alias.isMatch),
      ],
    };
    final int currentMatches = countAliasMatches(alias);
    final String pattern = aliasPatternFor(
      texts,
      (Transaction transaction) =>
          transaction.fieldPayee.value == payeeId || Aliases.matchesTransaction(alias, transaction),
    );
    if (pattern.isEmpty || pattern == alias.fieldPattern.value) {
      return (currentMatches: currentMatches, pattern: null, matches: currentMatches);
    }
    final int matches = countAliasMatches(
      Alias(id: -1, pattern: pattern, flags: AliasType.regex.index, payeeId: payeeId, data: this),
    );
    final bool isBetter =
        matches > currentMatches || (matches == currentMatches && pattern.length < alias.fieldPattern.value.length);
    return (currentMatches: currentMatches, pattern: isBetter ? pattern : null, matches: matches);
  }

  /// The texts [alias]'s pattern spells out: the plain pattern, or the texts of a regex that only lists texts.
  List<String> _textsListedIn(Alias alias) {
    final String pattern = alias.fieldPattern.value;
    if (alias.type == AliasType.none) {
      return <String>[pattern];
    }
    final AliasPatternParts? parsed = parseAliasPattern(pattern);
    return parsed == null ? <String>[] : literalTextsOf(parsed.parts) ?? <String>[];
  }
}
