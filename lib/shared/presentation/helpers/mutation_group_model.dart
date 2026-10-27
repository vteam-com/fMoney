import 'package:flutter/widgets.dart';

/// Represents a group of mutations that have occurred on a money object.
/// The `title` field provides a description of the group of mutations,
/// and the `whatWasMutated` field contains a list of widgets that
/// visually represent the specific mutations that occurred.
class MutationGroup {
  String title = '';
  List<Widget> whatWasMutated = <Widget>[];
}
