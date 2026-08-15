import 'package:flutter/material.dart';

const double _readOnlyHorizontalPadding = 12;
const double _readOnlyOpacity = 0.5;
const double _editableOpacity = 1.0;

/// Builds a form field wrapper with optional read-only styling.
Widget myFormField({
  required String title,
  required Widget child,
  bool isReadOnly = false,
}) {
  return InputDecorator(
    decoration: myFormFieldDecoration(fieldName: title, isReadOnly: isReadOnly),
    child: child,
  );
}

/// Creates InputDecoration with optional read-only appearance.
InputDecoration myFormFieldDecoration({
  required String fieldName,
  required bool isReadOnly,
}) {
  return InputDecoration(
    labelText: fieldName,
    contentPadding: isReadOnly ? const EdgeInsets.symmetric(horizontal: _readOnlyHorizontalPadding) : null,
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

/// State for my form field for widget.
class MyFormFieldForWidgetState extends State<MyFormFieldForWidget> {
  TextEditingController controller = TextEditingController();
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    controller.value = TextEditingValue(text: widget.valueAsText);
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.isReadOnly ? _readOnlyOpacity : _editableOpacity,
      child: TextFormField(
        controller: controller,
        decoration: myFormFieldDecoration(
          fieldName: widget.title,
          isReadOnly: widget.isReadOnly,
        ),
        onChanged: (String value) {
          setState(() {
            widget.onChanged(value);
          });
        },
      ),
    );
  }
}
