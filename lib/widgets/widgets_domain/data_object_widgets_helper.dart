import 'package:flutter/material.dart';
import 'package:money/data/models/field_type_enum.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/widgets/pure/form_field_switch_widget.dart';
import 'package:money/widgets/pure/form_field_widget.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';
import 'package:money/widgets/widgets_domain/data_object_widget_builders_model.dart';
import 'package:money/widgets/widgets_domain/field_model.dart';
import 'package:money/widgets/widgets_domain/field_widgets_helper.dart';

const double _readOnlyOpacity = 0.5;
const double _editableOpacity = 1.0;
const double _dividerAlpha = 0.5;
const int _valueFlex = 2;
const double _labelPaddingRight = 10;

///
/// Name: Bob
/// Date: 2020-12-31
/// Builds one name/value widget per detail-panel field of [instance], using [builders] for entity-specific widgets.
List<Widget> buildListOfNamesValuesWidgets(
  DataObject instance, {
  required DataObjectWidgetBuilders builders,
  void Function(bool /* wasModified */)? onEdit,
  bool compact = false,
}) {
  if (instance.fieldDefinitions.isEmpty) {
    return <Widget>[
      Center(
        child: Text(
          AppL10n.tr(AppTranslationKeys.noFieldsFoundForItem, params: <String, String>{'item': instance.toString()}),
        ),
      ),
    ];
  }
  final List<Widget> widgets = <Widget>[];

  {
    final FieldDefinitions definitions = instance.getFieldDefinitionsForPanel();

    for (final Field<dynamic> fieldDefinition in definitions) {
      final Widget widget = _buildWidgetNameValueFromFieldDefinition(
        objectInstance: instance,
        fieldDefinition: fieldDefinition,
        builders: builders,
        singleLineNameValue: compact, // when passing true, the onEdit is ignored
        onEdited: onEdit,
      );
      widgets.add(
        Padding(
          padding: compact ? const EdgeInsets.all(0) : const EdgeInsets.all(SizeForPadding.normal),
          child: widget,
        ),
      );
    }
  }

  // Also add the MoneyObject ID
  widgets.add(
    Padding(
      padding: const EdgeInsets.all(SizeForPadding.medium),
      child: Opacity(
        opacity: _readOnlyOpacity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(AppL10n.tr(AppTranslationKeys.idLabel)),
            SelectableText(instance.uniqueId.toString()),
          ],
        ),
      ),
    ),
  );

  return widgets;
}

/// Builds a name/value widget for a specific [fieldDefinition] on [objectInstance].
Widget _buildWidgetNameValueFromFieldDefinition({
  required DataObject objectInstance,
  required Field<dynamic> fieldDefinition,
  required DataObjectWidgetBuilders builders,
  required bool singleLineNameValue,
  required void Function(bool)? onEdited,
}) {
  final dynamic fieldValue = fieldDefinition.getValueForDisplay(
    objectInstance,
  );

  if (singleLineNameValue) {
    // simple [Name  Value] pair
    return _buildNameValuePair(objectInstance, fieldDefinition, fieldValue, builders);
  }
  final bool isReadOnly = onEdited == null || fieldDefinition.setValue == null;

  final InputDecoration decoration = myFormFieldDecoration(
    fieldName: fieldDefinition.name,
    isReadOnly: isReadOnly,
  );

  // Editing Field
  if (!isReadOnly) {
    final Widget? editWidget = builders.buildEditWidget(objectInstance, fieldDefinition, onEdited);
    if (editWidget != null) {
      // Editing mode and the MoneyObject has a custom edit widget
      return InputDecorator(
        decoration: InputDecoration(
          labelText: fieldDefinition.name,
          border: const OutlineInputBorder(),
        ),
        child: editWidget,
      );
    }
  }

  // Read only
  switch (fieldDefinition.type) {
    case FieldType.toggle:
      if (isReadOnly) {
        return MyFormFieldForWidget(
          title: fieldDefinition.name,
          valueAsText: fieldDefinition.getValueForDisplay(objectInstance).toString(),
          isReadOnly: true,
          onChanged: (String _) {},
        );
      }
      return InputDecorator(
        decoration: InputDecoration(
          labelText: fieldDefinition.name,
          border: const OutlineInputBorder(),
        ),
        child: SwitchFormField(
          title: fieldDefinition.name,
          initialValue: fieldDefinition.getValueForDisplay(objectInstance) as bool,
          isReadOnly: isReadOnly,
          validator: (bool? _) {
            /// Todo
            return null;
          },
          onSaved: (bool? value) {
            fieldDefinition.setValue?.call(objectInstance, value);
            onEdited(true);
          },
        ),
      );

    case FieldType.widget:
      final String valueAsString = fieldDefinition.getValueForSerialization(objectInstance).toString();
      return Opacity(
        opacity: isReadOnly ? _readOnlyOpacity : _editableOpacity,
        child: MyFormFieldForWidget(
          title: fieldDefinition.name,
          valueAsText: valueAsString,
          isReadOnly: isReadOnly,
          onChanged: (String value) {
            fieldDefinition.setValue?.call(objectInstance, value);
            onEdited?.call(false);
          },
        ),
      );

    // all others will be a normal text input
    default:
      String value = fieldDefinition.getString(fieldValue);
      if (value.isEmpty && isReadOnly) {
        value = '';
      }
      return Row(
        children: <Widget>[
          Expanded(
            child: Opacity(
              opacity: isReadOnly ? _readOnlyOpacity : _editableOpacity,
              child: TextFormField(
                initialValue: value,
                decoration: decoration,
                // allow mutation of the value
                readOnly: isReadOnly,

                onFieldSubmitted: (String _) {
                  onEdited?.call(false);
                },
                onEditingComplete: () {
                  onEdited?.call(false);
                },
                onChanged: (String newValue) {
                  fieldDefinition.setValue!(objectInstance, newValue);
                  onEdited?.call(false);
                },
              ),
            ),
          ),
        ],
      );
  }
}

/// Builds a compact name/value row used by detail panels.
Widget _buildNameValuePair(
  DataObject objectInstance,
  Field<dynamic> fieldDefinition,
  dynamic fieldValue,
  DataObjectWidgetBuilders builders,
) {
  return DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: Colors.grey.withValues(alpha: _dividerAlpha),
        ),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              0,
              0,
              _labelPaddingRight,
              0,
            ),
            child: Text(fieldDefinition.name),
          ),
        ),
        Expanded(
          flex: _valueFlex,
          child: Align(
            alignment: Alignment.centerRight,
            child:
                builders.buildFieldWidget(objectInstance, fieldDefinition) ??
                buildFieldValueWidgetForDetailView(fieldDefinition, fieldValue),
          ),
        ),
      ],
    ),
  );
}
