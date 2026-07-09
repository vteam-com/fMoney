# RULES for project fMoney

Here are the rules to follow and conform to when making code changes.

## No magic numbers

Use named constants in `lib/helpers/constants.dart` or a dedicated size/const class (e.g. `SizeForPadding`, `SizeForText`, `SizeForIcon`).

## One class per file

Prefer one primary class per file.

## Avoid extensions

Prefer top-level helpers, dedicated helper classes, or clearly-scoped instance methods over extension methods.
Do not use extensions to split large files; move shared behavior into subfiles instead.

### Class for stateful Widget should use a private _ prefix

- MyWidget
- _MyWidgetState

### allows special case

- Co-locate small helper/value classes only
- Tightly coupled (constants, field types, small UI helpers).
- use `// ignore: fcheck_one_class_per_file` to sielence `fcheck`

### Private class

- Class A calls Class _B
- Class _B

## No secret data in the code

Never commit API keys, tokens, or customer data.

## No Cycle dependencies

Keep the dependency graph acyclic; use `tool/graph.sh`/`lakos` when changing cross-layer imports.

## No lower layer code calling upper layer

Keep lower layers (data/helpers) independent of `views/`; prefer `helpers` or `widgets_domain` for shared interfaces.

## No dead code

Remove unused functions/classes and stale commented blocks unless there's a scoped TODO with context.

## Follow analyzer/linter settings

Always specify types, prefer final locals/fields, prefer const constructors, prefer single quotes, annotate overrides, and avoid `print`.

## Formatting

`dart format` uses a 120-character line width and preserves trailing commas. Use trailing commas for multi-line args/collections.

## Imports

Order imports as `dart:` first, then `package:`, then local `package:money/...`.
do not use relative path `import "../source.dart"` use `package:`

## Data model patterns

Entities: use `fromJson(MyJson row, ...)` factories and `fieldX` definitions with `Field*` types; provide static `Fields<T>` for column/view definitions.
Collections: extend `MoneyObjects<T>`, set `collectionName` in the constructor, implement `loadFromJson` and `toCSV`, and inject `DataAbstract` via `late`.

## Error reporting

Use `SnackBarService` for user-facing errors and `logger`/helpers for diagnostics; avoid raw `print`.

## fcheck clean

as part of the `tool/check.sh`, the `fcheck` must run clean
