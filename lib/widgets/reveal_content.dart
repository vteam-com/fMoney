import 'package:flutter/material.dart';
import 'package:money/helpers/misc_helpers.dart';

class RevealContent extends StatefulWidget {
  const RevealContent({
    required this.widgets,
    super.key,
    this.textForClipboard = '',
  });

  final String textForClipboard;
  final List<Widget> widgets;

  @override
  RevealContentState createState() => RevealContentState();
}

class RevealContentState extends State<RevealContent> {
  int _showItem = 0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggleReveal,
      onLongPress: () {
        if (widget.textForClipboard.isNotEmpty) {
          copyToClipboardAndInformUser(context, widget.textForClipboard);
        }
      },
      child: widget.widgets[_showItem],
    );
  }

  void _toggleReveal() {
    setState(() {
      _showItem++;
      if (_showItem >= widget.widgets.length) {
        _showItem = 0;
      }
    });
  }
}
