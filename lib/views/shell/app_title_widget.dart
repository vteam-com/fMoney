import 'package:money/helpers/amount_model.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/shared/domain/data_facade.dart';
import 'package:money/shared/presentation/helpers/mru_dropdown_widget.dart';
import 'package:money/shared/presentation/providers/data_file_controller_provider.dart';
import 'package:money/views/panels/layout/pending_changes_badge_widget.dart';
import 'package:money/widgets/components/reveal_content_widget.dart';
import 'package:money/widgets/pure/gaps_helper.dart';
import 'package:money/widgets/pure/scale_down_widget.dart';

// Exports
export 'package:money/shared/domain/data_facade.dart';

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
    final DataFileController dataController = DataFileController.to;

    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints _) {
        if (context.isWidthSmall) {
          return _buildCompactTitle(context, dataController);
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IntrinsicWidth(child: _buildNetWorthToggle(context)),
                gapSmall(),
                ListenableBuilder(
                  listenable: dataController.trackMutations,
                  builder: (BuildContext _, Widget? _) {
                    return BadgePendingChanges(
                      key: Constants.keyPendingChanges,
                      itemsAdded: dataController.trackMutations.added,
                      itemsChanged: dataController.trackMutations.changed,
                      itemsDeleted: dataController.trackMutations.deleted,
                    );
                  },
                ),
              ],
            ),
            const MruDropdown(),
          ],
        );
      },
    );
  }

  /// Builds the compact app title layout for small-width surfaces.
  Widget _buildCompactTitle(
    final BuildContext context,
    final DataFileController dataController,
  ) {
    return Row(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            reverse: true,
            scrollDirection: Axis.horizontal,
            child: IntrinsicWidth(child: _buildNetWorthToggle(context)),
          ),
        ),
        gapSmall(),
        ListenableBuilder(
          listenable: dataController.trackMutations,
          builder: (BuildContext _, Widget? _) {
            return BadgePendingChanges(
              key: Constants.keyPendingChanges,
              itemsAdded: dataController.trackMutations.added,
              itemsChanged: dataController.trackMutations.changed,
              itemsDeleted: dataController.trackMutations.deleted,
            );
          },
        ),
      ],
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
    fontSize: SizeForText.medium,
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
