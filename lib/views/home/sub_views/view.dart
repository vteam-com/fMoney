import 'package:flutter/widgets.dart';

// Exports
export 'package:flutter/widgets.dart';

abstract class ViewWidget extends StatefulWidget {
  const ViewWidget({super.key});

  @override
  State<ViewWidget> createState();

  String getClassNamePlural();

  String getClassNameSingular();

  String getDescription();
}

abstract class ViewWidgetState<T extends ViewWidget> extends State<T> {
  @override
  Widget build(final BuildContext context) {
    return LayoutBuilder(
      builder: (final BuildContext context, final BoxConstraints constraints) {
        return Column(
          children: <Widget>[
            buildHeader(),
            Expanded(child: buildViewContent(const Center(child: Text('Content goes here')))),
          ],
        );
      },
    );
  }

  Widget buildHeader([final Widget? child]);

  Widget buildViewContent(final Widget child);
}
