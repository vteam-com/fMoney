import 'package:flutter/material.dart';
import 'package:money/data/models/mutation_type_enum.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/json_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/domain/money_objects_collection_base.dart';
import 'package:money/shared/presentation/helpers/mutation_group_model.dart';
import 'package:money/widgets/pure/diff_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:money/widgets/widgets_domain/data_object_model.dart';

const double _diffIdOpacity = 0.5;

/// Groups the objects of [data] with the given [typeOfMutation] by table, for the pending changes UI.
List<MutationGroup> getMutationGroups(Data data, MutationType typeOfMutation) {
  final List<MutationGroup> allMutationGroups = <MutationGroup>[];

  for (final MoneyObjects<dynamic> moneyObjects in data.tables) {
    final List<DataObject> mutatedInstances = moneyObjects.getMutatedObjects(
      typeOfMutation,
    );
    if (mutatedInstances.isNotEmpty) {
      final MutationGroup mutationGroup = MutationGroup();
      mutationGroup.title = moneyObjects.collectionName;
      mutationGroup.whatWasMutated = buildWhatWasMutatedWidgets(
        mutatedInstances,
      );
      allMutationGroups.add(mutationGroup);
    }
  }
  return allMutationGroups;
}

/// Builds UI widgets describing what fields changed for the given objects.
List<Widget> buildWhatWasMutatedWidgets(List<DataObject> objects) {
  final List<Widget> widgets = <Widget>[];
  for (final DataObject moneyObject in objects) {
    final MyJson jsonDelta = moneyObject.getMutatedDiff<dynamic>();

    final List<Widget> diffWidgets = <Widget>[];

    jsonDelta.forEach((String key, dynamic value) {
      // Field Name
      final Widget instanceName = Text(
        key,
        style: const TextStyle(fontSize: SizeForText.small),
      );

      switch (moneyObject.mutation) {
        case MutationType.inserted:
          final String valueToAddAsString = value['after'].toString();
          if (valueToAddAsString.isNotEmpty) {
            diffWidgets.add(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  instanceName,
                  diffTextNewValue(valueToAddAsString),
                ],
              ),
            );
          }

        case MutationType.deleted:
          diffWidgets.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                instanceName,
                diffTextOldValue(value['after'].toString()),
              ],
            ),
          );
        case MutationType.changed:
        default:
          diffWidgets.add(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                instanceName,
                diffTextOldValue(value['before'].toString()),
                diffTextNewValue(value['after'].toString()),
              ],
            ),
          );
      }
    });

    widgets.add(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                moneyObject.getRepresentation(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Opacity(
                opacity: _diffIdOpacity,
                child: SelectableText(
                  moneyObject.uniqueId.toString(),
                  style: const TextStyle(fontSize: SizeForText.small),
                ),
              ),
            ],
          ),
          gapSmall(),
          Padding(
            padding: const EdgeInsets.only(left: SizeForPadding.normal),
            child: Wrap(
              spacing: SizeForPadding.large,
              runSpacing: SizeForPadding.large,
              children: diffWidgets,
            ),
          ),
        ],
      ),
    );
  }
  return widgets;
}
