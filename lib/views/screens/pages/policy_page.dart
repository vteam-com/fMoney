import 'package:money/helpers/app_l10n.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/views/screens/home/view_policy.dart';
import 'package:money/widgets/components/text_title.dart';

/// Represents policy page.
class PolicyPage extends StatelessWidget {
  const PolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: TextTitle(AppL10n.tr(AppTranslationKeys.policy)), centerTitle: true),
      body: Container(
        color: getColorTheme(context).surface,
        child: const SafeArea(child: PolicyScreen()),
      ),
    );
  }
}
