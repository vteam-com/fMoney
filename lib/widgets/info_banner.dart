import 'package:money/controller/theme_controller.dart';

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
    final Color color = getColorFromState(type);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(message, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}
