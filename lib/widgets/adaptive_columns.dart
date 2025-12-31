import 'package:money/widgets/widgets.dart';

class AdaptiveColumns extends StatelessWidget {
  /// Constructor
  const AdaptiveColumns({
    super.key,
    required this.columnWidth,
    required this.children,
  });

  final List<Widget> children;

  final int columnWidth;

  @override
  Widget build(final BuildContext context) => context.isWidthSmall ? singleColumn() : multiColumns();

  Widget multiColumns() => LayoutBuilder(
    builder: (final BuildContext context, final BoxConstraints constraints) {
      // how many columnsWidth  can fit in the give container
      final int quantity = (constraints.maxWidth / columnWidth).floor();

      // if theres only 1 column then just use the entire width
      final double? optimalColumnWidth = quantity <= 1 ? null : constraints.maxWidth / quantity;

      final List<Widget> sizedWidgets = children
          .map(
            (Widget widget) => Container(
              padding: const EdgeInsets.all(4),
              width: optimalColumnWidth,
              child: widget,
            ),
          )
          .toList();

      return Center(
        child: LayoutBuilder(
          builder: (final BuildContext context, final BoxConstraints constraints) => Wrap(
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.start,
            // // Horizontal spacing between the children
            // spacing: 10,
            // // Vertical spacing between the children
            // runSpacing: 10,
            children: sizedWidgets,
          ),
        ),
      );
    },
  );

  /// For small device list a phone simply use a single list of fields
  Widget singleColumn() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: children,
  );
}
