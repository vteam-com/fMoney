import 'package:flutter/material.dart';
import 'package:money/core/helpers/misc_helpers.dart';
import 'package:money/core/widgets/my_text_input.dart';

class FilterInput extends StatelessWidget {
  FilterInput({
    super.key,
    required this.hintText,
    required this.initialValue,
    required this.onChanged,
    required this.autoSubmitAfterSeconds,
  });

  late final Debouncer _debouncerForFilterText = Debouncer(
    Duration(seconds: autoSubmitAfterSeconds),
  );

  final int autoSubmitAfterSeconds;

  final String hintText;

  final String initialValue;

  final void Function(String) onChanged;

  @override
  Widget build(final BuildContext context) {
    return MyTextInput(
      initialValue: initialValue,
      icon: Icons.search,
      isDense: true,
      hintText: hintText,
      onFieldSubmitted: (String text) {
        onChanged(text);
      },
      onChanged: (final String text) {
        // optional auto submit
        if (autoSubmitAfterSeconds != -1) {
          _debouncerForFilterText.run(() {
            onChanged(text);
          });
        }
      },
    );
  }
}
