import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/app_update_service.dart';
import 'package:money/helpers/github_release_model.dart';
import 'package:money/helpers/shared_strings_helper.dart';
import 'package:path/path.dart' as p;

/// The release archive key of the platform running the tests.
String get _platformKey => Platform.isMacOS
    ? SharedStrings.platformKeyMacos
    : Platform.isWindows
    ? SharedStrings.platformKeyWindows
    : SharedStrings.platformKeyLinux;

/// A zip holding what an update of the running app must contain: an `.app` bundle on macOS,
/// a file named like the running executable elsewhere; with [holdsApp] false, an unrelated file.
List<int> _updateZip({required bool holdsApp}) {
  final String entry = !holdsApp
      ? 'readme.txt'
      : Platform.isMacOS
      ? 'money.app/Contents/MacOS/money'
      : p.basename(Platform.resolvedExecutable);
  final Archive archive = Archive()..add(ArchiveFile.bytes(entry, <int>[1, 2, 3]));
  return ZipEncoder().encode(archive);
}

/// Serves [body] with [statusCode] on a local port for the length of the test; returns its URL.
Future<String> _serve(List<int> body, {int statusCode = HttpStatus.ok}) async {
  final HttpServer server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  addTearDown(() => server.close(force: true));
  server.listen((HttpRequest request) async {
    request.response
      ..statusCode = statusCode
      ..contentLength = body.length
      ..add(body);
    await request.response.close();
  });
  return 'http://${server.address.host}:${server.port}/mymoney-app-$_platformKey.zip';
}

/// A release offering [url] as this platform's archive.
GitHubRelease _releaseAt(String url) =>
    GitHubRelease(assetUrls: <String, String>{_platformKey: url}, pageUrl: '', tagName: 'v99.0.0');

/// The temporary folders that [AppUpdateService.downloadUpdate] has left behind.
List<String> _updateFolders() => Directory.systemTemp
    .listSync()
    .map((FileSystemEntity entity) => entity.path)
    .where((String path) => p.basename(path).startsWith('fmoney-update-'))
    .toList();

void main() {
  group('AppUpdateService.downloadUpdate', () {
    test('extracts the app into a new folder and drops the archive', () async {
      final Directory folder = await AppUpdateService.downloadUpdate(
        _releaseAt(await _serve(_updateZip(holdsApp: true))),
      );
      addTearDown(() => folder.delete(recursive: true));

      final List<String> names = folder
          .listSync(recursive: true)
          .map((FileSystemEntity entity) => p.relative(entity.path, from: folder.path))
          .toList();
      expect(names, isNot(contains(endsWith('.zip'))));
      expect(
        names,
        contains(p.join('extracted', Platform.isMacOS ? 'money.app' : p.basename(Platform.resolvedExecutable))),
      );
    });

    test('refuses an archive without the app and removes its folder', () async {
      final List<String> before = _updateFolders();
      await expectLater(
        AppUpdateService.downloadUpdate(_releaseAt(await _serve(_updateZip(holdsApp: false)))),
        throwsA(isA<FileSystemException>()),
      );
      expect(_updateFolders(), before);
    });

    test('fails on an HTTP error and removes its folder', () async {
      final List<String> before = _updateFolders();
      await expectLater(
        AppUpdateService.downloadUpdate(_releaseAt(await _serve(<int>[], statusCode: HttpStatus.notFound))),
        throwsA(isA<HttpException>()),
      );
      expect(_updateFolders(), before);
    });
  });

  group('AppUpdateService.isNewerVersion', () {
    test('a higher major, minor or patch is newer', () {
      expect(AppUpdateService.isNewerVersion('2.0.0', '1.99.99'), isTrue);
      expect(AppUpdateService.isNewerVersion('1.21.0', '1.20.9'), isTrue);
      expect(AppUpdateService.isNewerVersion('1.20.1', '1.20.0'), isTrue);
    });

    test('compares numbers, not text', () {
      expect(AppUpdateService.isNewerVersion('1.20.10', '1.20.9'), isTrue);
      expect(AppUpdateService.isNewerVersion('1.9.0', '1.10.0'), isFalse);
    });

    test('accepts the release tag with its leading v', () {
      expect(AppUpdateService.isNewerVersion('v1.21.0', '1.20.0'), isTrue);
    });

    test('the same or an older version is not newer', () {
      expect(AppUpdateService.isNewerVersion('v1.20.0', '1.20.0'), isFalse);
      expect(AppUpdateService.isNewerVersion('1.19.9', '1.20.0'), isFalse);
    });

    test('old timestamp tags and other text are never newer', () {
      expect(AppUpdateService.isNewerVersion('v20260819-140219', '1.20.0'), isFalse);
      expect(AppUpdateService.isNewerVersion('1.21', '1.20.0'), isFalse);
      expect(AppUpdateService.isNewerVersion('', '1.20.0'), isFalse);
      expect(AppUpdateService.isNewerVersion('1.21.0', 'unknown'), isFalse);
    });
  });

  test('updates are not offered from debug and test builds', () {
    expect(AppUpdateService.isSupported, isFalse);
  });
}
