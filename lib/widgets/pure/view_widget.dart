import 'package:flutter/widgets.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';

// Exports
export 'package:flutter/widgets.dart';

/// Base class for all view widgets in the application.
abstract class ViewWidget extends StatefulWidget {
  const ViewWidget({super.key});

  @override
  State<ViewWidget> createState();

  /// Returns the plural class name for the view.
  String getClassNamePlural();

  /// Returns the singular class name for the view.
  String getClassNameSingular();

  /// Returns the description text for the view.
  String getDescription();
}

/// Base state class for [ViewWidget] providing common layout structure.
abstract class ViewWidgetState<T extends ViewWidget> extends State<T> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints _) {
        return Column(
          children: <Widget>[
            buildHeader(),
            Expanded(child: buildViewContent(Center(child: Text(AppL10n.tr(AppTranslationKeys.contentGoesHere))))),
          ],
        );
      },
    );
  }

  /// Builds the header widget with optional child.
  Widget buildHeader([Widget? child]);

  /// Builds the main view content widget.
  Widget buildViewContent(Widget child);
}
