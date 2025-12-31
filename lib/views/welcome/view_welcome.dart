import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:money/constants.dart';
import 'package:money/controller/data_controller.dart';
import 'package:money/views/home/sub_views/mru_dropdown.dart';
import 'package:money/widgets/gaps.dart';

// Exports
export 'package:flutter/material.dart';

/// The `WelcomeScreen` is a `StatelessWidget` that represents the welcome screen of the application.
/// It provides the user with options to create a new file, open an existing file, or use demo data.
class WelcomeScreen extends StatelessWidget {
  /// Constructs a new instance of the `WelcomeScreen` widget.
  const WelcomeScreen({super.key});

  @override
  Widget build(final BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Spacer(),
          const Text('Choose an option to get started:', style: TextStyle(fontSize: 16)),
          gapLarge(),
          Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              OutlinedButton(
                onPressed: () {
                  DataController.to.onFileNew();
                  Get.offAllNamed<dynamic>(Constants.routeHomePage);
                },
                child: const Text('New File ...'),
              ),
              OutlinedButton(
                onPressed: () async {
                  final bool succeeded = await DataController.to.onFileOpen();
                  if (succeeded) {
                    Get.offAllNamed<dynamic>(Constants.routeHomePage);
                  }
                },
                child: const Text('Open File ...'),
              ),
              OutlinedButton(
                onPressed: () async {
                  DataController.to.closeFile();
                  await DataController.to.loadDemoData();
                  Get.offAllNamed<dynamic>(Constants.routeHomePage);
                },
                child: const Text('Use Demo Data'),
              ),
            ],
          ),
          gapLarge(),
          const MruDropdown(),
          const Spacer(),
          IntrinsicWidth(
            child: Opacity(
              opacity: 0.5,
              child: Row(
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      Get.toNamed<dynamic>(Constants.routePolicyPage);
                    },
                    child: const Text('Privacy Policy'),
                  ),
                  gapLarge(),
                  TextButton(
                    onPressed: () {
                      showLicensePage(context: context);
                    },
                    child: const Text('Licenses'),
                  ),
                ],
              ),
            ),
          ),
          gapLarge(),
        ],
      ),
    );
  }
}
