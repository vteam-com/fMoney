import 'package:flutter/widgets.dart';

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
  Widget build(final BuildContext context) {
    return LayoutBuilder(
      builder: (final BuildContext _, final BoxConstraints _) {
        return Column(
          children: <Widget>[
            buildHeader(),
            Expanded(child: buildViewContent(const Center(child: Text('Content goes here')))),
          ],
        );
      },
    );
  }

  /// Builds the header widget with optional child.
  Widget buildHeader([final Widget? child]);

  /// Builds the main view content widget.
  Widget buildViewContent(final Widget child);
}
