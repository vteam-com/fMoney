import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

const double _dropOverlayAlpha = 0.2;
const double _dropOverlayFontSize = 24;

class DropZone extends StatefulWidget {
  const DropZone({
    super.key,
    required this.child,
    required this.onFilesDropped,
  });

  final Widget child;
  final void Function(List<String> filePaths) onFilesDropped;

  @override
  DropZoneState createState() => DropZoneState();
}

class DropZoneState extends State<DropZone> {
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (final DropDoneDetails detail) {
        widget.onFilesDropped(
          detail.files.map((DropItem x) => x.path).toList(),
        );
        setState(() {
          _dragging = false;
        });
      },
      onDragEntered: (DropEventDetails detail) {
        setState(() {
          _dragging = true;
        });
      },
      onDragExited: (DropEventDetails detail) {
        setState(() {
          _dragging = false;
        });
      },
      child: Stack(
        children: <Widget>[
          widget.child,
          if (_dragging)
            Container(
              color: Colors.blue.withValues(alpha: _dropOverlayAlpha),
              child: const Center(
                child: Text(
                  'Drop files here',
                  style: TextStyle(
                    fontSize: _dropOverlayFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
