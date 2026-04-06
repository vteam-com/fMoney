import 'dart:math';

import 'package:flutter/material.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';

const double _inactiveOpacity = 0.3;
const double _activeOpacity = 1;
const double _bannerRotationDegrees = -5;
const double _degreesToRadians = pi / 180;
const double _bannerFontSize = 10;

/// A stateless widget for my banner.
class MyBanner extends StatelessWidget {
  const MyBanner({required this.child, required this.on, super.key});

  final Widget child;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Opacity(
          opacity: on ? _inactiveOpacity : _activeOpacity,
          child: child,
        ),
        if (on)
          Transform.rotate(
            angle: _bannerRotationDegrees * _degreesToRadians, // Convert degrees to radians
            child: Container(
              color: Colors.grey,
              child: Text(
                AppL10n.tr(AppTranslationKeys.skippingDuplicate),
                style: const TextStyle(color: Colors.black, fontSize: _bannerFontSize),
              ),
            ),
          ),
      ],
    );
  }
}
