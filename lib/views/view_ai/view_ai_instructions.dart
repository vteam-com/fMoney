import 'package:flutter/material.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/widgets/pure/box.dart';
import 'package:money/widgets/pure/gaps.dart';
import 'package:money/widgets/pure/my_svg.dart';
import 'package:money/widgets/text_title.dart';

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
            const TextTitle('Ollama AI Assistant'),
            gapMedium(),
            const Text(
              'Ollama is required to use the AI assistant. Click below to install it.',
              textAlign: TextAlign.center,
            ),
            gapLarge(),
            if (!isOllamaInstalled)
              ElevatedButton(
                onPressed: onInstall,
                child: const Text('Install Ollama now'),
              ),
            if (!isOllamaRunning)
              ElevatedButton(
                onPressed: onCheckStatus,
                child: const Text('Run Ollama'),
              ),
          ],
        ),
      ),
    );
  }
}
