import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppL10n resolver coverage', () {
    test('covers every AppTranslationKeys constant in the resolver switch cases', () {
      final String keyFileSource = File('lib/helpers/app_translation_keys.dart').readAsStringSync();
      final RegExp keyPattern = RegExp(r"static const String (\\w+) = '[^']+';");
      final Set<String> declaredKeys = keyPattern
          .allMatches(keyFileSource)
          .map((final RegExpMatch match) => match.group(1)!)
          .toSet();

      final String resolverSource = File('lib/helpers/app_l10n_resolver_helper.dart').readAsStringSync();
      final RegExp resolverPattern = RegExp(r'AppTranslationKeys\\.(\\w+)');
      final Set<String> mappedKeys = resolverPattern
          .allMatches(resolverSource)
          .map((final RegExpMatch match) => match.group(1)!)
          .toSet();

      final List<String> missingKeys = declaredKeys.difference(mappedKeys).toList()..sort();

      expect(
        missingKeys,
        isEmpty,
        reason: 'Missing AppL10n resolver mappings: ${missingKeys.join(', ')}',
      );
    });
  });
}
