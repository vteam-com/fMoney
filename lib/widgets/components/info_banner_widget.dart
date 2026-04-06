import 'package:flutter/material.dart';
import 'package:money/widgets/pure/theme_custom_model.dart';

const double _bannerBorderRadius = 4;
const double _bannerHorizontalPadding = 16;
const double _bannerVerticalPadding = 8;
const double _bannerIconSpacing = 8;

/// A stateless widget for info banner.
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    required this.type,
    required this.message,
    required this.icon,
    super.key,
  });

  factory InfoBanner.error(String message) {
    return InfoBanner(
      type: ColorState.error,
      message: message,
      icon: Icons.error,
    );
  }

  factory InfoBanner.success(String message) {
    return InfoBanner(
      type: ColorState.success,
      message: message,
      icon: Icons.check_circle,
    );
  }

  factory InfoBanner.warning(String message) {
    return InfoBanner(
      type: ColorState.warning,
      message: message,
      icon: Icons.warning,
    );
  }

  final IconData icon;
  final String message;
  final ColorState type;

  @override
  Widget build(BuildContext context) {
    final Color color = context.colorTheme.getColorForState(type);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(_bannerBorderRadius),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: _bannerHorizontalPadding,
        vertical: _bannerVerticalPadding,
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: _bannerIconSpacing),
          Expanded(
            child: Text(message, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}
