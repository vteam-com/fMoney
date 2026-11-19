import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/alias_pattern_parser_helper.dart';

/// One line of an alias pattern explanation, indented [depth] levels under the line it details.
typedef AliasExplanationLine = ({int depth, String text});

/// Explains in plain words what [alias] matches, one line per part of its pattern.
List<AliasExplanationLine> explainAliasPattern(Alias alias) {
  final String pattern = alias.fieldPattern.value;
  if (pattern.isEmpty) {
    return <AliasExplanationLine>[];
  }
  if (alias.type == AliasType.none) {
    return <AliasExplanationLine>[
      (
        depth: 0,
        text: AppL10n.tr(AppTranslationKeys.aliasPatternExactText, params: <String, String>{'text': pattern}),
      ),
    ];
  }
  final AliasPatternParts? parsed = parseAliasPattern(pattern);
  if (parsed == null) {
    return <AliasExplanationLine>[(depth: 0, text: AppL10n.tr(AppTranslationKeys.aliasPatternInvalid))];
  }
  return <AliasExplanationLine>[
    (
      depth: 0,
      text: AppL10n.tr(
        parsed.ignoreCase ? AppTranslationKeys.aliasPatternIgnoreCase : AppTranslationKeys.aliasPatternMatchCase,
      ),
    ),
    ..._explainParts(parsed.parts, 0),
    (depth: 0, text: AppL10n.tr(AppTranslationKeys.aliasPatternWholeText)),
  ];
}

/// Describes a part that is not a group, ignoring how many times it repeats.
String _describe(AliasPatternPart part) {
  return switch (part.kind) {
    AliasPatternPartKind.text => AppL10n.tr(
      AppTranslationKeys.aliasPatternText,
      params: <String, String>{'text': part.text},
    ),
    AliasPatternPartKind.anyCharacter => AppL10n.tr(AppTranslationKeys.aliasPatternAnyCharacter),
    AliasPatternPartKind.digit => AppL10n.tr(AppTranslationKeys.aliasPatternDigit),
    AliasPatternPartKind.space => AppL10n.tr(AppTranslationKeys.aliasPatternSpace),
    AliasPatternPartKind.wordCharacter => AppL10n.tr(AppTranslationKeys.aliasPatternWordCharacter),
    AliasPatternPartKind.characterSet => AppL10n.tr(
      AppTranslationKeys.aliasPatternCharacterSet,
      params: <String, String>{'set': part.text},
    ),
    AliasPatternPartKind.notCharacterSet => AppL10n.tr(
      AppTranslationKeys.aliasPatternNotCharacterSet,
      params: <String, String>{'set': part.text},
    ),
    AliasPatternPartKind.start => AppL10n.tr(AppTranslationKeys.aliasPatternStart),
    AliasPatternPartKind.end => AppL10n.tr(AppTranslationKeys.aliasPatternEnd),
    AliasPatternPartKind.choices => AppL10n.tr(AppTranslationKeys.aliasPatternGroup),
    AliasPatternPartKind.other => AppL10n.tr(
      AppTranslationKeys.aliasPatternOther,
      params: <String, String>{'part': part.text},
    ),
  };
}

/// Explains [part] at [depth]; a group or choice adds the lines of what it contains below it.
List<AliasExplanationLine> _explainPart(AliasPatternPart part, int depth) {
  if (part.kind != AliasPatternPartKind.choices) {
    return <AliasExplanationLine>[(depth: depth, text: _phraseFor(part) ?? _repeated(_describe(part), part))];
  }
  if (part.choices.length == 1) {
    return <AliasExplanationLine>[
      (depth: depth, text: _repeated(_describe(part), part)),
      ..._explainParts(part.choices.first, depth + 1),
    ];
  }
  return <AliasExplanationLine>[
    (
      depth: depth,
      text: _repeated(
        AppL10n.tr(AppTranslationKeys.aliasPatternChoices, params: <String, String>{'count': '${part.choices.length}'}),
        part,
      ),
    ),
    for (int index = 0; index < part.choices.length; index++)
      ..._explainChoice(part.choices[index], index + 1, depth + 1),
  ];
}

/// Explains choice number [number] at [depth], its parts one level below.
List<AliasExplanationLine> _explainChoice(List<AliasPatternPart> parts, int number, int depth) =>
    <AliasExplanationLine>[
      (
        depth: depth,
        text: AppL10n.tr(AppTranslationKeys.aliasPatternChoice, params: <String, String>{'number': '$number'}),
      ),
      ..._explainParts(parts, depth + 1),
    ];

/// Explains each of [parts] at [depth].
List<AliasExplanationLine> _explainParts(List<AliasPatternPart> parts, int depth) => <AliasExplanationLine>[
  for (final AliasPatternPart part in parts) ..._explainPart(part, depth),
];

/// Returns the words for the common repeated parts (`.*`, `.+` and `\d+`), or null for the others.
String? _phraseFor(AliasPatternPart part) {
  if (part.max != null) {
    return null;
  }
  return switch ((part.kind, part.min)) {
    (AliasPatternPartKind.anyCharacter, 0) => AppL10n.tr(AppTranslationKeys.aliasPatternAnyTextOrNothing),
    (AliasPatternPartKind.anyCharacter, 1) => AppL10n.tr(AppTranslationKeys.aliasPatternAnyText),
    (AliasPatternPartKind.digit, 1) => AppL10n.tr(AppTranslationKeys.aliasPatternNumber),
    _ => null,
  };
}

/// Adds to [item] how many times [part] repeats, unless it appears once.
String _repeated(String item, AliasPatternPart part) {
  final int min = part.min;
  final int? max = part.max;
  final String? key = switch ((min, max)) {
    (1, 1) => null,
    (0, 1) => AppTranslationKeys.aliasPatternOptional,
    (0, null) => AppTranslationKeys.aliasPatternZeroOrMore,
    (1, null) => AppTranslationKeys.aliasPatternOneOrMore,
    (_, null) => AppTranslationKeys.aliasPatternAtLeast,
    _ when min == max => AppTranslationKeys.aliasPatternExactly,
    _ => AppTranslationKeys.aliasPatternBetween,
  };
  return key == null
      ? item
      : AppL10n.tr(key, params: <String, String>{'item': item, 'min': '$min', 'max': '${max ?? ''}'});
}
