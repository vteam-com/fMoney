import 'package:flutter/material.dart';

Widget myFormField({
  required final String title,
  required final Widget child,
  final bool isReadOnly = false,
}) {
  return InputDecorator(
    decoration: myFormFieldDecoration(fieldName: title, isReadOnly: isReadOnly),
    child: child,
  );
}

InputDecoration myFormFieldDecoration({
  required final String fieldName,
  required final bool isReadOnly,
}) {
  return InputDecoration(
    labelText: fieldName,
    contentPadding: isReadOnly ? const EdgeInsets.symmetric(horizontal: 12) : null,
    // some padding to match the Editable fields that have a border and padding
    border: const OutlineInputBorder(),
  );
}

/// Hybrid widget Text on the left, custom widget on the right
class MyFormFieldForWidget extends StatefulWidget {
  const MyFormFieldForWidget({
    required this.title,
    required this.valueAsText,
    required this.isReadOnly,
    required this.onChanged,
    super.key,
  });

  final bool isReadOnly;
  final void Function(String) onChanged;
  final String title;
  final String valueAsText;

  @override
  MyFormFieldForWidgetState createState() => MyFormFieldForWidgetState();
}

class MyFormFieldForWidgetState extends State<MyFormFieldForWidget> {
  TextEditingController controller = TextEditingController();
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    controller.value = TextEditingValue(text: widget.valueAsText);
  }

  @override
  Widget build(final BuildContext context) {
    return Opacity(
      opacity: widget.isReadOnly ? 0.5 : 1.0,
      child: TextFormField(
        controller: controller,
        decoration: myFormFieldDecoration(
          fieldName: widget.title,
          isReadOnly: widget.isReadOnly,
        ),
        onChanged: (final String value) {
          setState(() {
            widget.onChanged(value);
          });
        },
      ),
    );
  }
}
