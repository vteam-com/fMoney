import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/box.dart';
import 'package:money/widgets/ocr.dart';

class InputValues extends StatelessWidget {
  const InputValues({
    super.key,
    required this.controller,
    required this.title,
    required this.allowedCharacters,
    required this.expectAmountAsInputValues,
  });

  final String allowedCharacters;

  final TextEditingController controller;

  final bool expectAmountAsInputValues;

  final String title;

  @override
  Widget build(BuildContext context) {
    final int lineCount = getLineCount(controller.text);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Box(
          height: 200,
          width: 800,
          header: buildHeaderTitleAndCounter(
            context,
            title,
            '${getIntAsText(lineCount)} lines',
          ),
          child: TextField(
            key: const Key('key_input_text_field_value'),
            controller: controller,
            // focusNode: focusNode,
            autofocus: false,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(
              fontSize: SizeForText.medium,
              overflow: TextOverflow.fade,
            ),
            inputFormatters: <TextInputFormatter>[
              _TextInputFormatterRemoveEmptyLines(), // remove empty line
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: PasteImageOcr(
            textController: controller,
            allowedCharacters: allowedCharacters,
            expectAmountAsInputValues: expectAmountAsInputValues,
          ),
        ),
      ],
    );
  }
}

/// Text formatter that removes empty lines from input while preserving
/// trailing newlines if present in the original input
class _TextInputFormatterRemoveEmptyLines extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String cleanedText = removeEmptyLines(newValue.text);
    if (newValue.text.endsWith('\n')) {
      cleanedText += '\n';
    }

    if (newValue.text != cleanedText) {
      return newValue.copyWith(text: cleanedText);
    }
    return newValue;
  }
}
