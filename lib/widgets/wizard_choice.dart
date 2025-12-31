import 'package:money/constants.dart';
import 'package:money/helpers/color_helper.dart';

class WizardChoice extends StatelessWidget {
  const WizardChoice({
    super.key,
    required this.title,
    required this.description,
    required this.onPressed,
  });

  final String description;
  final void Function() onPressed;
  final String title;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            8.0,
          ), // Adjust the value to change the radius
        ),
      ),
      onPressed: () {
        onPressed();
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: ListTile(
          title: Text(title),
          titleTextStyle: TextStyle(
            fontSize: 20,
            color: getColorTheme(context).onSurface,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: SizeForPadding.medium),
            child: Text(description),
          ),
          trailing: const Icon(Icons.arrow_forward_ios),
        ),
      ),
    );
  }
}
