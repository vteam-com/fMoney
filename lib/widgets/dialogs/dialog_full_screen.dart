import 'package:money/widgets/components/app_scaffold_widget.dart';

const double _actionButtonSpacing = 8;
const double _actionButtonOverflowSpacing = 0;

///
class FullScreenDialog extends StatefulWidget {
  const FullScreenDialog({
    required this.title,
    required this.content,
    super.key,
    this.actionButtons = const <Widget>[],
  });

  final List<Widget> actionButtons;
  final Widget content;
  final String title;

  @override
  FullScreenDialogState createState() => FullScreenDialogState();
}

/// State for full screen dialog.
class FullScreenDialogState extends State<FullScreenDialog> {
  @override
  Widget build(BuildContext context) {
    return myScaffold(
      context,
      AppBar(title: Text(widget.title)),
      Column(
        children: <Widget>[
          Expanded(child: widget.content),
          if (widget.actionButtons.isNotEmpty)
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: _actionButtonSpacing,
              overflowAlignment: OverflowBarAlignment.end,
              overflowDirection: VerticalDirection.down,
              overflowSpacing: _actionButtonOverflowSpacing,
              children: widget.actionButtons,
            ),
        ],
      ),
    );
  }
}
