import 'package:flutter/widgets.dart';
import 'package:money/helpers/app_l10n_resolver_helper.dart';
import 'package:money/helpers/app_router_service.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/l10n/app_localizations.dart';

/// Provides access to Flutter AppLocalizations without requiring BuildContext.
class AppL10n {
  AppL10n._();

  /// Returns a localized string for [key] with optional [params].
  static String tr(String key, {Map<String, String>? params}) {
    final AppLocalizations l10n = _localizations;
    final Map<String, String> p = params ?? <String, String>{};
    return resolveAppL10nKey(l10n, key, p);
  }

  /// Resolves the current [AppLocalizations] using app context or locale fallback.
  static AppLocalizations get _localizations {
    final BuildContext? context = AppRouter.context;
    if (context != null) {
      final AppLocalizations? localized = AppLocalizations.of(context);
      if (localized != null) {
        return localized;
      }
    }
    final Locale locale = WidgetsBinding.instance.platformDispatcher.locale;
    final bool isSupported = AppLocalizations.supportedLocales.any(
      (Locale supported) => supported.languageCode == locale.languageCode,
    );
    return lookupAppLocalizations(Locale(isSupported ? locale.languageCode : SharedStrings.localeCodeEnglish));
  }
}
