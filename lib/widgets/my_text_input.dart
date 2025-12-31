import 'package:flutter/material.dart';

class MyTextInput extends StatelessWidget {
  MyTextInput({
    super.key,
    this.initialValue,
    this.isDense = false,
    this.border = true,
    IconData? icon,
    this.controller,
    this.hintText = '',
    this.onChanged,
    this.onFieldSubmitted,
  }) : decoration = InputDecoration(
         border: border ? const OutlineInputBorder() : null,
         prefixIcon: icon == null ? null : Icon(icon),
         isDense: isDense,
         // isCollapsed: isDense,
         // contentPadding: isDense ? EdgeInsets.zero : null,
         labelText: hintText,
         hintText: hintText,
       );

  final bool border;
  final TextEditingController? controller;
  final InputDecoration decoration;
  final String hintText;
  final String? initialValue;
  final bool isDense;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      controller: controller,
      decoration: decoration,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}
