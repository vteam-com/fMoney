import 'package:flutter/material.dart';
import 'package:money/helpers/constants_helper.dart';
import 'package:money/widgets/pure/gaps_helper.dart';

/// Display a message to the user
void messageBox(final BuildContext context, final String message) {
  showDialog<dynamic>(
    context: context,
    builder: (BuildContext _) {
      return SimpleDialog(
        children: <Widget>[
          gapLarge(),
          Padding(padding: const EdgeInsets.all(SizeForPadding.large), child: Text(message)),
          gapLarge(),
        ],
      );
    },
  );
}

/// Represents dialog service.
class DialogService {
  factory DialogService() => _instance;

  DialogService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // singleton
  static final DialogService _instance = DialogService._internal();
}
