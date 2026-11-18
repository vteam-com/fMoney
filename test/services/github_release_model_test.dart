import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/github_release_model.dart';

void main() {
  group('GitHubRelease.fromJson', () {
    test('reads the tag, the page and each platform archive', () {
      final GitHubRelease release = GitHubRelease.fromJson(<String, dynamic>{
        'tag_name': 'v1.21.0',
        'html_url': 'https://github.com/vteam-com/fMoney/releases/tag/v1.21.0',
        'assets': <dynamic>[
          <String, dynamic>{'name': 'mymoney-app-macos.zip', 'browser_download_url': 'https://example.com/mac.zip'},
          <String, dynamic>{'name': 'mymoney-app-windows.zip', 'browser_download_url': 'https://example.com/win.zip'},
          <String, dynamic>{
            'name': 'mymoney-app-linux.tar.gz',
            'browser_download_url': 'https://example.com/linux.tgz',
          },
          <String, dynamic>{'name': 'checksums.txt', 'browser_download_url': 'https://example.com/checksums.txt'},
        ],
      });

      expect(release.tagName, 'v1.21.0');
      expect(release.version, '1.21.0');
      expect(release.pageUrl, 'https://github.com/vteam-com/fMoney/releases/tag/v1.21.0');
      expect(release.assetUrls, <String, String>{
        'macos': 'https://example.com/mac.zip',
        'windows': 'https://example.com/win.zip',
        'linux': 'https://example.com/linux.tgz',
      });
    });

    test('a release without assets or fields reads as empty', () {
      final GitHubRelease release = GitHubRelease.fromJson(<String, dynamic>{});

      expect(release.tagName, isEmpty);
      expect(release.version, isEmpty);
      expect(release.pageUrl, isEmpty);
      expect(release.assetUrls, isEmpty);
    });
  });
}
