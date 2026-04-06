import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';

const double _dropOverlayAlpha = 0.2;
const double _dropOverlayFontSize = 24;

/// A stateful widget for drop zone.
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

/// State for drop zone.
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
      onDragEntered: (DropEventDetails _) {
        setState(() {
          _dragging = true;
        });
      },
      onDragExited:
          (
            DropEventDetails _, //detail
          ) {
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
              child: Center(
                child: Text(
                  AppL10n.tr(AppTranslationKeys.dropFilesHere),
                  style: const TextStyle(
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
