import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/widgets/pure/snack_bar.dart';
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
        label: const Text('OCR'),
      ),
    );
  }

  Future<ui.Image> fromBytesToImage(Uint8List list) async {
    // Decode the image
    final ui.Codec codec = await ui.instantiateImageCodec(list);
    final FrameInfo frameInfo = await codec.getNextFrame();

    return frameInfo.image;
  }

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
                widget.textController.text += '$cleanedAmount\n';
              }
            }
          } else {
            if (widget.textController.text.isNotEmpty) {
              widget.textController.text += '\n';
            }
            widget.textController.text += text;
          }
        }
      } on Exception catch (e) {
        // Handle potential errors
        logger.e('Error recognizing text: $e');
        SnackBarService.displayError(
          message: 'Failed to extract text from image.',
        );
      }
    } else {
      SnackBarService.displayError(
        title: 'OCR',
        message: 'No image found in clipboard.',
      );
    }
  }
}
