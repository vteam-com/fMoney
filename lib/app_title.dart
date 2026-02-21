import 'package:get/get.dart';
import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/views/data.dart';
import 'package:money/views/data_file_controller.dart';
import 'package:money/views/mru_dropdown.dart';
import 'package:money/views/panels/pending_changes/badge_pending_changes.dart';
import 'package:money/widgets/pure/gaps.dart';
import 'package:money/widgets/reveal_content.dart';

// Exports
export 'package:money/views/data.dart';

const double _revealIconOpacity = 0.8;
const double _revealIconSize = 16;

/// A stateless widget for app title.
class AppTitle extends StatelessWidget {
  AppTitle({super.key}) {
    netWorth = Data().getNetWorth();
  }

  late final AmountModel netWorth;

  /// Builds the app title widget including net worth reveal and MRU dropdown.
  @override
  Widget build(BuildContext context) {
    final DataFileController dataController = Get.find();

    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints _) {
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

  /// Builds the net worth reveal/toggle widget.
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

/// Builds a single reveal option row for [RevealContent].
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
        opacity: _revealIconOpacity,
        child: Icon(
          hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: _revealIconSize,
          color: color,
        ),
      ),
    ],
  );
}
