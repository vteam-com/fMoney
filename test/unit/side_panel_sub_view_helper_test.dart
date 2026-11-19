import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/views/panels/layout/side_panel_sub_view_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every side panel sub-view has its own label and icon', () {
    final List<String> labels = SidePanelSubViewEnum.values
        .map((SidePanelSubViewEnum subView) => AppL10n.tr(subView.labelKey))
        .toList();

    expect(labels.first, AppL10n.tr(AppTranslationKeys.details));
    expect(labels.toSet(), hasLength(SidePanelSubViewEnum.values.length));
    expect(
      SidePanelSubViewEnum.values.map((SidePanelSubViewEnum subView) => subView.iconData).toSet(),
      hasLength(SidePanelSubViewEnum.values.length),
    );
    expect(SidePanelSubViewEnum.aliases.iconData, ViewId.viewAliases.getIconData());
  });
}
