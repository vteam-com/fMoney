import 'package:dotted_border/dotted_border.dart';
import 'package:money/data/helpers/category_type_helper.dart';
import 'package:money/data/models/field_model.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/category_entity.dart';
import 'package:money/shared/domain/data_abstract_interface.dart';
import 'package:money/widgets/list/list_item_card.dart';
import 'package:money/widgets/pickers/mutate_field_color_widget.dart';
import 'package:money/widgets/pickers/picker_category_type.dart';
import 'package:money/widgets/pickers/token_text_widget.dart';
import 'package:money/widgets/pure/circle_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:money/widgets/widgets_domain/widget_from_data.dart';

const int _unsetId = -1;
const int _zeroInt = 0;
const double _colorSwatchSizeSmall = 12.0;

/// Returns the [Category]-specific display widget for [field], or null for the generic one.
Widget? buildCategoryFieldDisplayWidget(Category category, Field<dynamic> field) {
  if (field.isSameDefinition(category.fieldColor)) {
    return buildCategoryColorWidget(category);
  }
  if (field.isSameDefinition(category.fieldName)) {
    return buildCategoryNameWidget(category);
  }
  return null;
}

/// Returns the [Category]-specific editor for [field], or null for the generic one.
Widget? buildCategoryFieldEditWidget(
  Category category,
  Field<dynamic> field,
  void Function(bool /* wasModified */) onEdited,
) {
  if (field.isSameDefinition(category.fieldColor)) {
    return MutateFieldColor(
      colorAsHex: category.fieldColor.value,
      onEdited: (String newValue) {
        category.fieldColor.value = newValue;
        category.data!.notifyMutationChanged(
          mutation: MutationType.changed,
          moneyObject: category,
          recalculateBalances: false,
        );
        onEdited(true);
      },
    );
  }
  if (field.isSameDefinition(category.fieldType)) {
    return pickerCategoryType(
      itemSelected: category.fieldType.value,
      onSelected: (CategoryType selectedType) {
        category.fieldType.value = selectedType;
        onEdited(true);
      },
    );
  }
  return null;
}

/// Builds the small-screen card for [category].
Widget buildCategorySmallScreenWidget(Category category) {
  String top = '';
  String bottom = '';

  if (category.fieldParentId.value == _unsetId) {
    top = category.fieldName.value;
    bottom = '';
  } else {
    top = category.leafName;
    bottom = Category.getName(category.parentCategory);
  }

  return MyListItemAsCard(
    leftTopAsString: top,
    leftBottomAsString: bottom,
    rightTopAsWidget: WidgetFromData(
      amountModel: category.fieldSum.value,
      size: DataWidgetSize.title,
    ),
    rightBottomAsWidget: Row(
      children: <Widget>[
        Text(category.getTypeAsText()),
        gapMedium(),
        buildCategoryColorWidget(category),
      ],
    ),
  );
}

/// Returns a widget showing the color swatch and name of [category].
Widget buildCategoryColorAndNameWidget(Category category) {
  return Row(
    children: <Widget>[
      buildCategoryColorWidget(category),
      gapMedium(),
      Expanded(child: buildCategoryNameWidget(category)),
    ],
  );
}

/// Returns a color swatch widget for [category] with an optional level indicator.
Widget buildCategoryColorWidget(Category category) {
  final Color fillColor = category.getColorOrAncestorsColor();
  final Color textColor = fillColor.a == _zeroInt ? Colors.grey : contrastColor(fillColor);

  return Stack(
    alignment: Alignment.center,
    children: <Widget>[
      MyCircle(colorFill: fillColor, size: _colorSwatchSizeSmall),
      if (category.fieldColor.value.isNotEmpty && category.fieldLevel.getValueForDisplay(category) != '1')
        Text(
          '#',
          style: TextStyle(fontSize: SizeForText.small, color: textColor),
        ),
    ],
  );
}

/// Returns the name of [category] as a widget.
Widget buildCategoryNameWidget(Category category) {
  return TokenText(category.fieldName.value);
}

/// Returns a widget representing the category with the given [id].
Widget buildCategoryWidgetFromId(int id) {
  if (id == _unsetId) {
    return const Text('?');
  }

  if (id == DataAbstract.instance.getSplitCategoryId()) {
    return _buildSplitCategoryWidget();
  }

  final Category? category = DataAbstract.instance.getCategory(id) as Category?;
  return category == null ? Text(AppL10n.tr(AppTranslationKeys.unknown)) : buildCategoryColorAndNameWidget(category);
}

/// Builds the dotted placeholder shown for the split category.
Widget _buildSplitCategoryWidget() {
  return DottedBorder(
    options: RoundedRectDottedBorderOptions(
      color: Colors.grey.shade600,
      padding: const EdgeInsets.symmetric(horizontal: SizeForPadding.medium),
      radius: const Radius.circular(SizeForPadding.small),
    ),
    child: Text(AppL10n.tr(AppTranslationKeys.split)),
  );
}
