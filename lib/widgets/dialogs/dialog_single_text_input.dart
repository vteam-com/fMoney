import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/widgets/pure/gaps.dart';
import 'package:money/widgets/pure/my_text_input.dart';
import 'package:url_launcher/url_launcher.dart';

const double _dialogWidth = 400;
const double _dialogHeight = 200;

/// Shows a modal dialog with a single text input field.
Future<void> showTextInputDialog({
  required BuildContext context,
  required void Function(String) onContinue,
  final String title = 'Input',
  final String subTitle = '',
  final String initialValue = '',
  void Function()? onCancel,
}) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      final TextEditingController textEditingController = TextEditingController();
      textEditingController.text = initialValue;
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: _dialogWidth,
          height: _dialogHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Markdown(
                  data: subTitle,
                  selectable: true,
                  onTapLink: (String text, String? href, String title) {
                    if (text.isEmpty && title.isEmpty) {
                      // keep callback signature variables explicit for readability
                    }
                    launchUrl(Uri.parse(href!));
                  },
                ),
              ),
              gapLarge(),
              Expanded(
                child: MyTextInput(
                  key: const Key('key_single_input_dialog'),
                  controller: textEditingController,
                  hintText: 'Enter $title',
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onCancel?.call();
            },
            child: Text(AppL10n.tr(AppTranslationKeys.cancel)),
          ),
          ElevatedButton(
            onPressed: () {
              final String text = textEditingController.text;
              Navigator.pop(context);
              onContinue(text);
            },
            child: Text(AppL10n.tr(AppTranslationKeys.continueLabel)),
          ),
        ],
      );
    },
  );
}
