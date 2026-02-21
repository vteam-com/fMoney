import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:money/helpers/constants.dart';
import 'package:money/widgets/preferences_controller.dart';
import 'package:money/widgets/theme_controller.dart';

const double _defaultTextScale = 1.0;
const int _percentScale = 100;

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
                ThemeController.to.setFontScaleTo(_defaultTextScale);
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

  /// Updates [zoomValueAsText] based on the current preference text scale.
  void updateZoomTextFromValue() {
    zoomValueAsText = '${(preferenceController.textScale * _percentScale).toInt()}%';
  }
}
