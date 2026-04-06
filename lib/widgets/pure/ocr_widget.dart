import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:textify/textify.dart';

const double _ocrButtonScale = 0.6;

/// A stateful widget for paste image ocr.
class PasteImageOcr extends StatefulWidget {
  const PasteImageOcr({
    super.key,
    required this.textController,
    required this.allowedCharacters,
    this.expectAmountAsInputValues = false,
  });

  final String allowedCharacters;
  final bool expectAmountAsInputValues;
  final TextEditingController textController;

  @override
  State<PasteImageOcr> createState() => _PasteImageOcrState();
}

class _PasteImageOcrState extends State<PasteImageOcr> {
  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: _ocrButtonScale, // Adjust scale factor as needed (0.0 to 1.0)
      alignment: Alignment.bottomCenter, // Optional: Position the scaled button
      child: ElevatedButton.icon(
        onPressed: _recognizeTextFromClipboard,
        icon: const Icon(Icons.content_paste_go_outlined),
        label: Text(AppL10n.tr(AppTranslationKeys.ocr)),
      ),
    );
  }

  /// Decodes image bytes to a ui.Image for OCR processing.
  Future<ui.Image> fromBytesToImage(Uint8List list) async {
    // Decode the image
    final ui.Codec codec = await ui.instantiateImageCodec(list);
    final FrameInfo frameInfo = await codec.getNextFrame();

    return frameInfo.image;
  }

  /// Reads an image from the clipboard, runs OCR, and appends recognized text to the controller.
  Future<void> _recognizeTextFromClipboard() async {
    final Uint8List? bytes = await Pasteboard.image;
    if (bytes != null) {
      try {
        final ui.Image inputImage = await fromBytesToImage(bytes);

        // extract text from the image
        final String text = await (await Textify().init()).getTextFromImage(
          image: inputImage,
          supportedCharacters: widget.allowedCharacters,
        );
        text.trim();
        if (text.isNotEmpty) {
          if (widget.expectAmountAsInputValues) {
            final List<String> allAmounts = text.split('\n');

            for (final String amount in allAmounts) {
              final String cleanedAmount = amount
                  .replaceAll(RegExp(r'\((?!\))'), ',')
                  .replaceAll(RegExp(r'\(\)'), '')
                  .replaceAll(',,', ',')
                  .trim();
              if (cleanedAmount.isNotEmpty && cleanedAmount != ',' && cleanedAmount != '1') {
                widget.textController.text += '$cleanedAmount${SharedStrings.lineFeed}';
              }
            }
          } else {
            if (widget.textController.text.isNotEmpty) {
              widget.textController.text += SharedStrings.lineFeed;
            }
            widget.textController.text += text;
          }
        }
      } on Exception catch (e) {
        // Handle potential errors
        logger.e('Error recognizing text: $e');
        SnackBarService.displayError(
          message: SharedStrings.messageFailedToExtractTextFromImage,
        );
      }
    } else {
      SnackBarService.displayError(
        title: AppL10n.tr(AppTranslationKeys.ocr),
        message: SharedStrings.messageNoImageFoundInClipboard,
      );
    }
  }
}
