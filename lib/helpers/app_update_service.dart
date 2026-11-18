import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/generated_app_version_data.dart';
import 'package:money/helpers/github_artifacts_service.dart';
import 'package:money/helpers/github_release_model.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:path/path.dart' as p;

/// Finds a newer desktop release on GitHub and installs it over the running app.
///
/// [downloadUpdate] extracts the release archive for this platform into a temporary folder;
/// [launchInstaller] then starts a script that waits for this app to quit, puts the new files
/// in place and starts the app again.
abstract final class AppUpdateService {
  /// Folder, inside the update's temporary folder, that the release archive is extracted to.
  static const String _extractedFolderName = 'extracted';

  /// HTTP method of the download request.
  static const String _httpGet = 'GET';

  /// PowerShell options that run the Windows install script, unsigned and without a window,
  /// followed by the script path.
  static const List<String> _powershellOptions = <String>[
    '-NoProfile',
    '-ExecutionPolicy',
    'Bypass',
    '-WindowStyle',
    'Hidden',
    '-File',
  ];

  /// File written and deleted to test that the install folder accepts new files.
  static const String _writeProbeFileName = '.fmoney-update-probe';

  /// Installs a macOS update by swapping the whole `.app` bundle, restoring the old one if the swap fails.
  ///
  /// Arguments: app process id, new bundle, installed bundle, temporary folder to delete, app to start.
  static const String _macosInstallScript = r'''
while kill -0 "$1" 2>/dev/null; do sleep 1; done
rm -rf "$3.old"
if mv "$3" "$3.old"; then
  if mv "$2" "$3"; then
    rm -rf "$3.old"
  else
    rm -rf "$3"
    mv "$3.old" "$3"
  fi
fi
open "$5"
rm -rf "$4"
''';

  /// Installs a Linux update by copying the new files over the installed folder, which may hold other files.
  ///
  /// Arguments: app process id, new files folder, installed folder, temporary folder to delete, app to start.
  static const String _linuxInstallScript = r'''
while kill -0 "$1" 2>/dev/null; do sleep 1; done
cp -Rf "$2/." "$3/"
nohup "$5" >/dev/null 2>&1 &
rm -rf "$4"
''';

  /// Installs a Windows update by copying the new files over the installed folder, retrying
  /// while Windows still holds the old files locked.
  ///
  /// Arguments: app process id, new files folder, installed folder, temporary folder to delete, app to start.
  static const String _windowsInstallScript = r'''
param([int]$AppPid, [string]$Source, [string]$Target, [string]$TempDir, [string]$Program)
Wait-Process -Id $AppPid -ErrorAction SilentlyContinue
robocopy $Source $Target /E /R:10 /W:1 /NFL /NDL /NJH /NJS /NP | Out-Null
Start-Process -FilePath $Program
Remove-Item -LiteralPath $TempDir -Recurse -Force -ErrorAction SilentlyContinue
''';

  /// Matches a `major.minor.patch` version, with or without a leading `v`.
  static final RegExp _versionPattern = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)$');

  /// True on desktop release builds, the only builds installed from GitHub release archives.
  static bool get isSupported => kReleaseMode && _platformKey != null;

  /// True when this copy of the app can replace itself, that is when the folder the update
  /// writes to accepts new files (not the case under Program Files, or for a macOS app that
  /// runs from a read-only translocated folder because it was never moved out of Downloads).
  static bool canInstallInPlace() {
    final String? installed = _installedPath;
    if (installed == null) {
      return false;
    }
    // macOS swaps the bundle inside its parent folder; the others copy into the install folder
    final String folder = Platform.isMacOS ? p.dirname(installed) : installed;
    try {
      final File probe = File(p.join(folder, _writeProbeFileName));
      probe.writeAsStringSync('');
      probe.deleteSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Downloads [release]'s archive for this platform and extracts it into a new temporary
  /// folder, returned for [launchInstaller]. Throws when the download or the archive is bad.
  static Future<Directory> downloadUpdate(GitHubRelease release) async {
    final Uri url = Uri.parse(release.assetUrls[_platformKey]!);
    final Directory updateFolder = await Directory.systemTemp.createTemp('fmoney-update-');
    try {
      final File archive = File(p.join(updateFolder.path, p.basename(url.path)));
      await _download(url, archive);
      final String extracted = p.join(updateFolder.path, _extractedFolderName);
      await extractFileToDisk(archive.path, extracted, verify: true);
      // fail now, while the app is still open, if the archive does not hold the app
      _newAppPath(extracted);
      await archive.delete();
      return updateFolder;
    } catch (_) {
      await updateFolder.delete(recursive: true);
      rethrow;
    }
  }

  /// The latest GitHub release when it is newer than this app and has an archive for this
  /// platform; null otherwise, including when GitHub can't be reached.
  static Future<GitHubRelease?> findUpdate() async {
    final String? platformKey = _platformKey;
    if (platformKey == null) {
      return null;
    }
    final GitHubRelease? release = await GitHubArtifactsService.fetchLatestRelease();
    if (release == null ||
        !release.assetUrls.containsKey(platformKey) ||
        !isNewerVersion(release.tagName, GeneratedAppVersionData.version)) {
      return null;
    }
    return release;
  }

  /// True when [candidate] is a higher `major.minor.patch` version than [current]; false when
  /// either one is not such a version (for example the old timestamp release tags).
  static bool isNewerVersion(String candidate, String current) {
    final List<int>? candidateParts = _parseVersion(candidate);
    final List<int>? currentParts = _parseVersion(current);
    if (candidateParts == null || currentParts == null) {
      return false;
    }
    for (int index = 0; index < candidateParts.length; index++) {
      if (candidateParts[index] != currentParts[index]) {
        return candidateParts[index] > currentParts[index];
      }
    }
    return false;
  }

  /// Starts the script that, once this app quits, replaces the installed app with the one
  /// extracted in [updateFolder] by [downloadUpdate], then starts it.
  static Future<void> launchInstaller(Directory updateFolder) async {
    final String installed = _installedPath!;
    final String newApp = _newAppPath(p.join(updateFolder.path, _extractedFolderName));
    final List<String> scriptArguments = <String>[
      '$pid',
      newApp,
      installed,
      updateFolder.path,
      Platform.isMacOS ? installed : Platform.resolvedExecutable,
    ];

    if (Platform.isWindows) {
      final File script = File(p.join(updateFolder.path, 'install_update.ps1'));
      await script.writeAsString(_windowsInstallScript);
      await Process.start(
        'powershell.exe',
        <String>[..._powershellOptions, script.path, ...scriptArguments],
        mode: ProcessStartMode.detached,
      );
      return;
    }
    final File script = File(p.join(updateFolder.path, 'install_update.sh'));
    await script.writeAsString(Platform.isMacOS ? _macosInstallScript : _linuxInstallScript);
    await Process.start('/bin/sh', <String>[script.path, ...scriptArguments], mode: ProcessStartMode.detached);
  }

  /// What the update replaces: the `.app` bundle on macOS, the folder holding the executable on
  /// Windows and Linux; null when the running app is not laid out that way.
  static String? get _installedPath {
    final String executable = Platform.resolvedExecutable;
    if (Platform.isMacOS) {
      // money.app/Contents/MacOS/money
      final String bundle = p.dirname(p.dirname(p.dirname(executable)));
      return p.extension(bundle) == '.app' ? bundle : null;
    }
    return p.dirname(executable);
  }

  /// The release archive key of this platform, or null when releases have no archive for it.
  static String? get _platformKey {
    if (kIsWeb) {
      return null;
    }
    if (Platform.isMacOS) {
      return SharedStrings.platformKeyMacos;
    }
    if (Platform.isWindows) {
      return SharedStrings.platformKeyWindows;
    }
    if (Platform.isLinux) {
      return SharedStrings.platformKeyLinux;
    }
    return null;
  }

  /// Saves [url] to [destination], failing on an error status, a stalled transfer or a short file.
  static Future<void> _download(Uri url, File destination) async {
    final http.Client client = http.Client();
    try {
      final http.Request request = http.Request(_httpGet, url)
        ..headers['User-Agent'] = GitHubArtifactsService.userAgent;
      final http.StreamedResponse response = await client.send(request).timeout(Constants.httpRequestTimeout);
      if (response.statusCode != Constants.httpStatusOk) {
        throw HttpException('Download failed with status ${response.statusCode}', uri: url);
      }
      await response.stream.timeout(Constants.httpRequestTimeout).pipe(destination.openWrite());
      final int? expectedLength = response.contentLength;
      if (expectedLength != null && await destination.length() != expectedLength) {
        throw HttpException('Download ended early', uri: url);
      }
    } finally {
      client.close();
    }
  }

  /// The new app inside the [extracted] archive: the `.app` bundle on macOS, the folder holding
  /// an executable named like this one elsewhere. Throws when the archive does not hold it.
  static String _newAppPath(String extracted) {
    if (Platform.isMacOS) {
      for (final FileSystemEntity entity in Directory(extracted).listSync()) {
        if (entity is Directory && p.extension(entity.path) == '.app') {
          return entity.path;
        }
      }
    } else if (File(p.join(extracted, p.basename(Platform.resolvedExecutable))).existsSync()) {
      return extracted;
    }
    throw FileSystemException('The update archive does not contain the app', extracted);
  }

  /// The numbers of a `major.minor.patch` [version], or null when it is not one.
  static List<int>? _parseVersion(String version) {
    final RegExpMatch? match = _versionPattern.firstMatch(version);
    if (match == null) {
      return null;
    }
    return <int>[for (int group = 1; group <= match.groupCount; group++) int.parse(match.group(group)!)];
  }
}
