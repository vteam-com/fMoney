import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/widgets/components/text_title.dart';
import 'package:money/widgets/pure/box.dart';
import 'package:money/widgets/pure/gaps.dart';
import 'package:money/widgets/pure/my_svg.dart';

const double _ollamaLogoSize = 64.0;

/// A stateless widget for view ai instructions.
class ViewAIInstructions extends StatelessWidget {
  const ViewAIInstructions({
    super.key,
    this.isOllamaInstalled = false,
    this.isOllamaRunning = false,
    this.onCheckStatus,
    this.onInstall,
  });

  final bool isOllamaInstalled;
  final bool isOllamaRunning;
  final VoidCallback? onCheckStatus;
  final VoidCallback? onInstall;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Box(
        padding: SizeForPadding.large,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MySvg(
              assetName: 'ollama.svg',
              size: _ollamaLogoSize,
              color: Theme.of(context).colorScheme.primary,
            ),
            gapLarge(),
            TextTitle(AppL10n.tr(AppTranslationKeys.ollamaAiAssistant)),
            gapMedium(),
            Text(
              AppL10n.tr(AppTranslationKeys.ollamaIsRequiredToUseTheAiAssistantClickBelowToInstallIt),
              textAlign: TextAlign.center,
            ),
            gapLarge(),
            if (!isOllamaInstalled)
              ElevatedButton(
                onPressed: onInstall,
                child: Text(AppL10n.tr(AppTranslationKeys.installOllamaNow)),
              ),
            if (!isOllamaRunning)
              ElevatedButton(
                onPressed: onCheckStatus,
                child: Text(AppL10n.tr(AppTranslationKeys.runOllama)),
              ),
          ],
        ),
      ),
    );
  }
}
