import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/app_l10n_resolver_helper.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/l10n/app_localizations_en.dart';

import '../../tool/l10n_keys_generator_helper.dart';

void main() {
  group('AppL10n generated keys and resolver', () {
    final List<L10nMessage> messages = parseMessages(File(localizationsPath).readAsStringSync());

    test('parses getters and parameterized methods from AppLocalizations', () {
      expect(messages, isNotEmpty);
      final L10nMessage atLeast = messages.firstWhere((L10nMessage m) => m.name == 'aliasPatternAtLeast');
      expect(atLeast.parameters, <String>['item', 'min']);
      expect(messages.firstWhere((L10nMessage m) => m.name == 'appName').parameters, isEmpty);
    });

    test('generated files are up to date with app_en.arb', () {
      final Map<String, String> expected = buildGeneratedSources(messages);
      for (final MapEntry<String, String> entry in expected.entries) {
        expect(
          _normalized(File(entry.key).readAsStringSync()),
          _normalized(entry.value),
          reason: '${entry.key} is stale: run `dart run tool/l10n_keys_generator_helper.dart`',
        );
      }
      final List<String> staleStageFiles = Directory('lib/helpers')
          .listSync()
          .map((FileSystemEntity entity) => entity.path)
          .where((String path) => isResolverStageFile(path) && !expected.containsKey(path))
          .toList();
      expect(staleStageFiles, isEmpty);
    });

    test('resolves plain and parameterized keys, and returns unknown keys unchanged', () {
      final AppLocalizationsEn l10n = AppLocalizationsEn();
      expect(resolveAppL10nKey(l10n, AppTranslationKeys.appName, <String, String>{}), l10n.appName);
      expect(
        resolveAppL10nKey(l10n, AppTranslationKeys.aliasPatternAtLeast, <String, String>{'item': 'x', 'min': '2'}),
        l10n.aliasPatternAtLeast('x', '2'),
      );
      expect(resolveAppL10nKey(l10n, 'notAKey', <String, String>{}), 'notAKey');
    });
  });
}

/// Ignores formatting differences (whitespace and formatter-added trailing commas).
String _normalized(String source) => source.replaceAll(RegExp(r'\s+'), '').replaceAll(',)', ')');
