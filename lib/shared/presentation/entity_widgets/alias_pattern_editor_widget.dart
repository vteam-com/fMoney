import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/shared/domain/alias_pattern_suggestion_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/presentation/entity_widgets/alias_pattern_explanation_helper.dart';
import 'package:money/widgets/pure/gaps_helper.dart';

/// Indent of each explanation level.
const double _explanationIndent = 16;

/// Edits an alias pattern, explains in plain words what it matches, and offers Optimize: a pattern
/// built from the data that matches more transactions or is shorter.
class AliasPatternEditor extends StatefulWidget {
  /// Creates the pattern editor of [alias]; [onEdited] reports each change, true when it changed the type too.
  const AliasPatternEditor({required this.alias, required this.onEdited, super.key});

  /// The alias whose pattern is edited.
  final Alias alias;

  /// Called after each edit of the alias.
  final void Function(bool wasModified) onEdited;

  @override
  State<AliasPatternEditor> createState() => _AliasPatternEditorState();
}

class _AliasPatternEditorState extends State<AliasPatternEditor> {
  late final TextEditingController _controller = TextEditingController(text: widget.alias.fieldPattern.value);

  /// The pattern, type and payee the [_suggestion] was made for.
  ({String pattern, int flags, int payeeId})? _suggestedFor;

  /// What Optimize found, while the alias is still as it was then ([_suggestedFor]).
  AliasPatternSuggestion? _suggestion;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? explanationStyle = getTextTheme(context).bodySmall;
    final AliasPatternSuggestion? suggestion = _suggestedFor == _stateOf(widget.alias) ? _suggestion : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          key: const Key('key_alias_pattern'),
          controller: _controller,
          decoration: const InputDecoration.collapsed(hintText: ''),
          onChanged: (String text) {
            widget.alias.fieldPattern.value = text;
            widget.onEdited(false);
          },
        ),
        gapMedium(),
        for (final AliasExplanationLine line in explainAliasPattern(widget.alias))
          Padding(
            padding: EdgeInsets.only(left: line.depth * _explanationIndent, bottom: SizeForPadding.nano),
            child: Text(line.text, style: explanationStyle),
          ),
        gapSmall(),
        if (suggestion == null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('key_alias_optimize'),
              icon: const Icon(Icons.auto_fix_high),
              label: Text(AppL10n.tr(AppTranslationKeys.aliasPatternOptimize)),
              onPressed: _optimize,
            ),
          )
        else
          ..._buildSuggestion(suggestion),
      ],
    );
  }

  /// Shows the better pattern Optimize found with a Use button, or says there is none.
  List<Widget> _buildSuggestion(AliasPatternSuggestion suggestion) {
    final String? pattern = suggestion.pattern;
    if (pattern == null) {
      return <Widget>[
        Text(
          AppL10n.tr(
            AppTranslationKeys.aliasPatternNoBetter,
            params: <String, String>{'count': getIntAsText(suggestion.currentMatches)},
          ),
        ),
      ];
    }
    return <Widget>[
      Text(
        AppL10n.tr(
          AppTranslationKeys.aliasPatternSuggested,
          params: <String, String>{
            'count': getIntAsText(suggestion.matches),
            'current': getIntAsText(suggestion.currentMatches),
          },
        ),
      ),
      Row(
        children: <Widget>[
          Expanded(child: SelectableText(pattern)),
          TextButton(
            key: const Key('key_alias_use_suggestion'),
            onPressed: () => _use(pattern),
            child: Text(AppL10n.tr(AppTranslationKeys.aliasPatternUseSuggestion)),
          ),
        ],
      ),
    ];
  }

  /// Looks for a better pattern in the data for the alias as it is now.
  void _optimize() {
    setState(() {
      _suggestion = Data().suggestAliasPattern(widget.alias);
      _suggestedFor = _stateOf(widget.alias);
    });
  }

  /// What a suggestion depends on: [alias]'s pattern, type and payee.
  ({String pattern, int flags, int payeeId}) _stateOf(Alias alias) =>
      (pattern: alias.fieldPattern.value, flags: alias.fieldFlags.value, payeeId: alias.fieldPayeeId.value);

  /// Makes [pattern] the alias's pattern, as a regex.
  void _use(String pattern) {
    _controller.text = pattern;
    widget.alias.fieldPattern.value = pattern;
    widget.alias.fieldFlags.value = AliasType.regex.index;
    setState(() => _suggestion = null);
    widget.onEdited(true);
  }
}
