// ignore: fcheck_secrets

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';

/// A stateless widget for policy screen.
class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SizeForPadding.large),
        child: Markdown(data: getMDContext(), selectable: true),
      ),
    );
  }

  /// Returns the privacy policy content as a Markdown string.
  String getMDContext() {
    return AppL10n.tr(AppTranslationKeys.privacyPolicyMarkdown);
  }
}
