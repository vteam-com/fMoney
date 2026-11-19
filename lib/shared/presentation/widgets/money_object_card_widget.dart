import 'package:money/data/models/data_object_model.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/misc_helpers.dart';
import 'package:money/helpers/string_helper.dart';
import 'package:money/shared/presentation/entity_widgets/entity_widgets_helper.dart';
import 'package:money/widgets/dialogs/button_helpers.dart';
import 'package:money/widgets/pure/box_widget.dart';
import 'package:money/widgets/pure/center_message_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:money/widgets/widgets_domain/data_object_widgets_helper.dart';

const double _adaptiveBoxHeight = 300.0;
const int _dividerAlpha = 100;

/// A stateless widget for money object card.
class MoneyObjectCard extends StatelessWidget {
  const MoneyObjectCard({
    required this.title,
    super.key,
    this.moneyObject,
    this.onEdit,
    this.onMergeWith,
    this.onDelete,
  });

  final DataObject? moneyObject;
  final void Function(BuildContext, List<DataObject>)? onDelete;
  final void Function(BuildContext, List<DataObject>)? onEdit;
  final void Function(BuildContext, DataObject?)? onMergeWith;
  final String title;

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgets = <Widget>[];

    // Header
    if (title.isNotEmpty) {
      widgets.add(_buildCardHeader(context));
    }

    // Content
    if (moneyObject == null) {
      widgets.add(Text(AppL10n.tr(AppTranslationKeys.notFound)));
    } else {
      widgets.add(gapLarge());
      widgets.addAll(
        buildListOfNamesValuesWidgets(moneyObject!, builders: entityWidgetBuilders, onEdit: null, compact: true),
      );
    }

    return Box(
      color: getColorTheme(context).primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ),
    );
  }

  /// Header Object [Name, Id, Actions]
  Widget _buildCardHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        // Title
        Text(title, style: getTextTheme(context).headlineSmall),

        // Header Action buttons
        Row(
          children: <Widget>[
            if (onMergeWith != null) buildMergeButton(() => onMergeWith?.call(context, moneyObject)),
            if (onEdit != null) buildEditButton(() => onEdit?.call(context, <DataObject>[moneyObject!])),
            if (onDelete != null) buildDeleteButton(() => onDelete?.call(context, <DataObject>[moneyObject!])),
            buildCopyButton(
              () => copyToClipboardAndInformUser(context, moneyObject!.getPersistableJSon().toString()),
              const Key('key_copy_money_object_card'),
              AppL10n.tr(AppTranslationKeys.copyToClipboard),
            ),
          ],
        ),
      ],
    );
  }
}

/// Builds an adaptive box titled [title] listing [count] rows made by [itemBuilder], separated by dividers.
Widget buildAdaptiveBox({
  required BuildContext context,
  required String title,
  required int count,
  required IndexedWidgetBuilder itemBuilder,
  Widget? footer,
}) {
  return Box(
    height: _adaptiveBoxHeight,
    color: getColorTheme(context).primaryContainer,
    header: buildHeaderTitleAndCounter(
      context,
      title,
      count == 0 ? '' : getIntAsText(count),
    ),
    footer: footer,
    padding: SizeForPadding.huge,
    child: count == 0
        ? CenterMessage(message: '${AppL10n.tr(AppTranslationKeys.noItems)} $title')
        : ListView.separated(
            itemCount: count,
            itemBuilder: itemBuilder,
            separatorBuilder: (BuildContext context, int _) => Divider(
              color: getColorTheme(context).onPrimaryContainer.withAlpha(_dividerAlpha),
            ),
          ),
  );
}
