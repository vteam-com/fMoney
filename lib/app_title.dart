import 'package:get/get.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/views/models/data/data.dart';
import 'package:money/views/models/data/data_controller.dart';
import 'package:money/views/models/mru_dropdown.dart';
import 'package:money/views/panels/pending_changes/badge_pending_changes.dart';
import 'package:money/widgets/gaps.dart';
import 'package:money/widgets/money_model.dart';
import 'package:money/widgets/reveal_content.dart';

// Exports
export 'package:money/views/models/data/data.dart';

class AppTitle extends StatelessWidget {
  AppTitle({super.key}) {
    netWorth = Data().getNetWorth();
  }

  late final MoneyModel netWorth;

  @override
  Widget build(BuildContext context) {
    final DataController dataController = Get.find();

    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                IntrinsicWidth(child: _buildNetWorthToggle(context)),
                gapSmall(),
                Obx(() {
                  return BadgePendingChanges(
                    key: Constants.keyPendingChanges,
                    itemsAdded: dataController.trackMutations.added.value,
                    itemsChanged: dataController.trackMutations.changed.value,
                    itemsDeleted: dataController.trackMutations.deleted.value,
                  );
                }),
              ],
            ),
            const MruDropdown(),
          ],
        );
      },
    );
  }

  Widget _buildNetWorthToggle(final BuildContext context) {
    return RevealContent(
      textForClipboard: netWorth.toString(),
      widgets: <Widget>[
        _buildRevealContentOption(context, 'fMoney', true),
        _buildRevealContentOption(context, netWorth.toShortHand(), false),
        _buildRevealContentOption(context, netWorth.toString(), false),
      ],
    );
  }
}

Widget _buildRevealContentOption(
  final BuildContext context,
  String text,
  final bool hidden,
) {
  final Color color = getColorTheme(context).onSurface;
  final TextStyle textStyle = TextStyle(
    fontSize: SizeForText.normal,
    color: color,
  );

  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      Text(text, style: textStyle),
      gapSmall(),
      Opacity(
        opacity: 0.8,
        child: Icon(
          hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 16,
          color: color,
        ),
      ),
    ],
  );
}
