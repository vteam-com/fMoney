import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/constants_helper.dart';

/// Label and icon shown for each side panel sub-view.
extension SidePanelSubViewDisplay on SidePanelSubViewEnum {
  /// Returns the translation key of this sub-view's label.
  String get labelKey => switch (this) {
    SidePanelSubViewEnum.details => AppTranslationKeys.details,
    SidePanelSubViewEnum.chart => AppTranslationKeys.chart,
    SidePanelSubViewEnum.transactions => AppTranslationKeys.transactions,
    SidePanelSubViewEnum.pnl => AppTranslationKeys.pnl,
    SidePanelSubViewEnum.aliases => AppTranslationKeys.aliases,
  };

  /// Returns the icon of this sub-view.
  IconData get iconData => switch (this) {
    SidePanelSubViewEnum.details => Icons.info_outline,
    SidePanelSubViewEnum.chart => Icons.bar_chart,
    SidePanelSubViewEnum.transactions => Icons.calendar_view_day,
    SidePanelSubViewEnum.pnl => Icons.balance,
    SidePanelSubViewEnum.aliases => ViewId.viewAliases.getIconData(),
  };
}
