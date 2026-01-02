import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:money/constants.dart';
import 'package:money/controller/preferences_controller.dart';
import 'package:money/controller/theme_controller.dart';

/// ( - )  100% ( + )
class ZoomIncreaseDecrease extends StatefulWidget {
  const ZoomIncreaseDecrease({
    super.key,
    required this.title,
    required this.onDecrease,
    required this.onIncrease,
  });

  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final String title;

  @override
  State<ZoomIncreaseDecrease> createState() => _ZoomIncreaseDecreaseState();
}

class _ZoomIncreaseDecreaseState extends State<ZoomIncreaseDecrease> {
  PreferenceController preferenceController = Get.find();
  String zoomValueAsText = '';

  @override
  void initState() {
    super.initState();
    updateZoomTextFromValue();
  }

  @override
  Widget build(final BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(widget.title),
        IconButton(
          key: Constants.keyZoomDecrease,
          tooltip: 'Cmd/Ctrl -',
          icon: const Icon(Icons.text_decrease),
          onPressed: () {
            setState(() {
              widget.onDecrease();
              updateZoomTextFromValue();
            });
          },
        ),
        Tooltip(
          key: Constants.keyZoomNormal,
          message: 'Cmd/Ctrl 0',
          child: TextButton(
            onPressed: () {
              setState(() {
                ThemeController.to.setFontScaleTo(1.0);
                updateZoomTextFromValue();
              });
            },
            child: Text(zoomValueAsText),
          ),
        ),
        IconButton(
          key: Constants.keyZoomIncrease,
          tooltip: 'Cmd/Ctrl +',
          icon: const Icon(Icons.text_increase),
          onPressed: () {
            setState(() {
              widget.onIncrease();
              updateZoomTextFromValue();
            });
          },
        ),
      ],
    );
  }

  void updateZoomTextFromValue() {
    zoomValueAsText = '${(preferenceController.textScale * 100).toInt()}%';
  }
}
