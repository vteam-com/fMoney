enum AliasType {
  none, // 0
  regex, // 1
}

String getAliasTypeAsString(final AliasType type) {
  switch (type) {
    case AliasType.none:
      return '=';
    case AliasType.regex:
      return 'RegExp';
  }
}
