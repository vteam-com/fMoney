# AGENTS Notes

- Always document any new API you add (public or private). Every new function, method, class, and shared helper must include a concise doc comment at creation time.
- avoid using "part" to break up files
- always use type anonation, const and final when and where applicable
- before marking work complete, run `tool/check.sh`; it must pass cleanly with zero warnings, zero errors, and a perfect score of `100%`

## Localization Guardrails

- Never ship user-facing display text as inline string literals in widgets or view models.
- Treat these as user-facing and localize them:
  - `Text('...')`, `TextSpan(text: '...')`, `Tooltip(message: '...')`, `SnackBar(content: Text('...'))`
  - navigation labels/tooltips such as `MyNavigationItem(label: '...', tooltip: '...')`
  - dialog titles/buttons/messages, menu labels, empty-state strings, error/status strings.
- Use standard Flutter localization (`AppLocalizations`) through project helper (`AppL10n.tr(AppTranslationKeys.someKey)`), not raw `.tr` literals.
- `AppTranslationKeys` values must be stable key IDs (for example `'settings'`), never English display strings.
- Every new key must be added to both:
  - `lib/l10n/app_en.arb`
  - `lib/l10n/app_fr.arb`
- For parameterized strings, use placeholders in ARB and `AppL10n.tr(..., params: {...})`.
- After localization edits, always run:
  - `flutter gen-l10n`
  - `flutter analyze`
  - `fcheck --list full .`
 - Before finishing, explicitly scan for probable missed display literals:
   - `rg -n "label:\\s*'|tooltip:\\s*'|Text\\('\\w|SnackBar\\(content:\\s*Text\\('|AppBar\\(title:\\s*Text\\('" lib`

## File Naming

- Use `snake_case` for *every* Dart file and include a suffix that reflects its primary role (`_view.dart`, `_screen.dart`, `_widget.dart`, `_panel.dart`, `_dialog.dart`, `_card.dart`, `_chart.dart`, `_service.dart`, `_controller.dart`, `_provider.dart`, `_repository.dart`, `_domain.dart`, `_model.dart`, `_helper.dart`, `_utils.dart`, `_state.dart`, `_data.dart`, `_test.dart`, etc.).
- Avoid generic filenames—constantly prefer `[feature]_[role].dart` (for example, `merge_payees_dialog.dart` instead of `merge_payees.dart`) so teammates see the intent without opening the file.
- When renaming to meet this convention, update all import/usage sites and rerun `flutter analyze` or `fcheck` to ensure the tree rebuilds cleanly.
