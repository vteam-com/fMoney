import 'package:flutter/material.dart';

class SwitchFormField extends FormField<bool> {
  SwitchFormField({
    required String title,
    required bool super.initialValue,
    required bool isReadOnly,
    required super.validator,
    required super.onSaved,
  }) : super(
         key: UniqueKey(),
         builder: (FormFieldState<bool> state) {
           return Switch(
             value: state.value!,
             onChanged: (bool value) {
               state.didChange(value);
               onSaved?.call(value);
             },
           );
         },
       );
}
