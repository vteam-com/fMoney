import 'package:money/helpers/shared_strings_helper.dart';

enum AliasType {
  none, // 0
  regex, // 1
}

/// Returns a short display string for the given alias [type].
String getAliasTypeAsString(final AliasType type) {
  switch (type) {
    case AliasType.none:
      return '=';
    case AliasType.regex:
      return SharedStrings.aliasTypeRegExp;
  }
}
