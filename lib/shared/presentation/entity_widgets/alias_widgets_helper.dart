import 'package:money/data/helpers/alias_type_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:money/shared/domain/alias_entity.dart';
import 'package:money/widgets/list/list_item_card.dart';

/// Builds the small-screen card for [alias].
Widget buildAliasSmallScreenWidget(Alias alias) {
  return MyListItemAsCard(
    leftTopAsString: alias.data!.getPayeeName(alias.fieldPayeeId.value),
    leftBottomAsString: alias.fieldPattern.value,
    rightBottomAsString: '${getAliasTypeAsString(alias.type)}${SharedDomainStrings.domainString158}',
  );
}
