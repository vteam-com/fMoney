import 'package:flutter_test/flutter_test.dart';
import 'package:money/helpers/github_artifacts_service.dart';

void main() {
  group('GitHubArtifactsService', () {
    test('getLatestArtifactUrls returns map with platform keys', () async {
      final Map<String, String> urls = await GitHubArtifactsService.getLatestArtifactUrls();
      expect(urls, isA<Map<String, String>>());

      // Should contain at least one platform or fallback URLs
      expect(urls.keys.any((String key) => <String>['windows', 'linux', 'macos'].contains(key)), true);
    });
  });
}
