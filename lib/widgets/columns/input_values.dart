import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/helpers/shared_strings.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/widgets/pure/box.dart';
import 'package:money/widgets/pure/ocr.dart';

const double _inputBoxHeight = 200;
const double _inputBoxWidth = 800;

/// A stateless widget for input values.
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
          height: _inputBoxHeight,
          width: _inputBoxWidth,
          header: buildHeaderTitleAndCounter(
            context,
            title,
            '${getIntAsText(lineCount)}${SharedStrings.suffixLines}',
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
