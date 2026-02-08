import 'package:money/helpers/color_helper.dart';
import 'package:money/helpers/constants.dart';

const double _choiceBorderRadius = 8;
const double _choiceMaxWidth = 400;
const double _choiceTitleFontSize = 20;

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
            _choiceBorderRadius,
          ), // Adjust the value to change the radius
        ),
      ),
      onPressed: () {
        onPressed();
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _choiceMaxWidth),
        child: ListTile(
          title: Text(title),
          titleTextStyle: TextStyle(
            fontSize: _choiceTitleFontSize,
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
