import 'package:money/widgets/app_scaffold.dart';

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
              spacing: 8,
              overflowAlignment: OverflowBarAlignment.end,
              overflowDirection: VerticalDirection.down,
              overflowSpacing: 0,
              children: widget.actionButtons,
            ),
        ],
      ),
    );
  }
}
