import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:money/helpers/app_l10n_service.dart';
import 'package:money/helpers/app_translation_keys.dart';
import 'package:money/helpers/app_update_service.dart';
import 'package:money/helpers/generated_app_version_data.dart';
import 'package:money/helpers/github_release_model.dart';
import 'package:money/helpers/window_manager_service.dart';
import 'package:money/widgets/pure/snack_bar_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Checks GitHub for a newer desktop release and, when there is one, shows a banner offering to
/// install it and restart, or to download it when this copy of the app can't replace itself.
///
/// The banner lives in the app's [ScaffoldMessenger], so it stays put while startup navigation
/// replaces pages, and it does not hold back snack bars.
Future<void> checkForAppUpdate() async {
  if (!AppUpdateService.isSupported) {
    return;
  }
  final GitHubRelease? release = await AppUpdateService.findUpdate();
  final ScaffoldMessengerState? messenger = SnackBarService.scaffoldKey.currentState;
  if (release == null || messenger == null) {
    return;
  }
  final bool canInstall = AppUpdateService.canInstallInPlace();

  messenger.showMaterialBanner(
    MaterialBanner(
      leading: const Icon(Icons.system_update),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppL10n.tr(
              AppTranslationKeys.updateAvailableMessage,
              params: <String, String>{
                'version': release.version,
                'currentVersion': GeneratedAppVersionData.version,
              },
            ),
          ),
          if (!canInstall) Text(AppL10n.tr(AppTranslationKeys.updateCannotInstallHere)),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: messenger.hideCurrentMaterialBanner,
          child: Text(AppL10n.tr(AppTranslationKeys.later)),
        ),
        TextButton(
          onPressed: () {
            messenger.hideCurrentMaterialBanner();
            if (canInstall) {
              _installUpdate(release);
            } else {
              launchUrl(Uri.parse(release.pageUrl));
            }
          },
          child: Text(
            AppL10n.tr(canInstall ? AppTranslationKeys.installAndRestart : AppTranslationKeys.download),
          ),
        ),
      ],
    ),
  );
}

/// Downloads [release], asks about unsaved changes, then quits so the installer can replace this
/// app and start the new version. Reports failures in a snack bar and leaves the app running.
Future<void> _installUpdate(GitHubRelease release) async {
  SnackBarService.displayInfo(
    message: AppL10n.tr(
      AppTranslationKeys.downloadingUpdate,
      params: <String, String>{'version': release.version},
    ),
  );
  Directory? updateFolder;
  try {
    final Directory downloaded = await AppUpdateService.downloadUpdate(release);
    updateFolder = downloaded;
    final bool quitting = await MyWindowManager.quitApp(
      beforeQuit: () => AppUpdateService.launchInstaller(downloaded),
    );
    if (!quitting) {
      // the user kept the app open to deal with unsaved changes
      await downloaded.delete(recursive: true);
    }
  } catch (error) {
    await updateFolder?.delete(recursive: true);
    SnackBarService.displayError(
      message: AppL10n.tr(
        AppTranslationKeys.updateFailed,
        params: <String, String>{'error': '$error'},
      ),
    );
  }
}
