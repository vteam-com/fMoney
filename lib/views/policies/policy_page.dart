import 'package:get/get.dart';
import 'package:money/helpers/color_helper.dart';
import 'package:money/views/policies/view_policy.dart';
import 'package:money/widgets/text_title.dart';

class PolicyPage extends GetView<GetxController> {
  const PolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const TextTitle('Policy'), centerTitle: true),
      body: Container(
        color: getColorTheme(context).surface,
        child: const SafeArea(child: PolicyScreen()),
      ),
    );
  }
}
