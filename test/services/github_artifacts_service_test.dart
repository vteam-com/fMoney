import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:money/helpers/github_artifacts_service.dart';
import 'package:money/helpers/github_release_model.dart';

/// Runs [body] with every `http` request answered by [handler], keyed on the request URL path.
Future<T> _withGitHub<T>(Future<T> Function() body, Map<String, Object> responsesByPath) => http.runWithClient(
  body,
  () => MockClient((http.Request request) async {
    final Object? response = responsesByPath[request.url.path];
    return response == null ? http.Response('', 404) : http.Response(json.encode(response), 200);
  }),
);

void main() {
  const String releasePath = '/repos/vteam-com/fMoney/releases/latest';
  const String runsPath = '/repos/vteam-com/fMoney/actions/workflows/builds.yml/runs';
  const String artifactsPath = '/repos/vteam-com/fMoney/actions/runs/7/artifacts';

  group('GitHubArtifactsService', () {
    test('uses the latest release archives, with fallback URLs for the platforms it lacks', () async {
      final Map<String, String> urls = await _withGitHub(
        GitHubArtifactsService.getLatestArtifactUrls,
        <String, Object>{
          releasePath: <String, Object>{
            'tag_name': 'v1.0.0',
            'assets': <Object>[
              <String, String>{'name': 'mymoney-app-macos.zip', 'browser_download_url': 'https://example.com/mac.zip'},
            ],
          },
        },
      );

      expect(urls, <String, String>{
        ...GitHubArtifactsService.fallbackUrls,
        'macos': 'https://example.com/mac.zip',
      });
    });

    test('uses the latest build artifacts when there is no release', () async {
      final Map<String, String> urls = await _withGitHub(
        GitHubArtifactsService.getLatestArtifactUrls,
        <String, Object>{
          runsPath: <String, Object>{
            'workflow_runs': <Object>[
              <String, int>{'id': 7},
            ],
          },
          artifactsPath: <String, Object>{
            'artifacts': <Object>[
              <String, String>{'name': 'mymoney-app-linux', 'archive_download_url': 'https://example.com/linux.zip'},
              <String, String>{'name': 'coverage', 'archive_download_url': 'https://example.com/coverage.zip'},
            ],
          },
        },
      );

      expect(urls, <String, String>{
        ...GitHubArtifactsService.fallbackUrls,
        'linux': 'https://example.com/linux.zip',
      });
    });

    test('returns the fallback URLs when GitHub has nothing', () async {
      final Map<String, String> urls = await _withGitHub(
        GitHubArtifactsService.getLatestArtifactUrls,
        <String, Object>{},
      );

      expect(urls, GitHubArtifactsService.fallbackUrls);
      expect(urls.keys, containsAll(<String>['windows', 'linux', 'macos']));
    });

    test('fetchLatestRelease returns null when GitHub answers with an error', () async {
      final GitHubRelease? release = await _withGitHub(
        GitHubArtifactsService.fetchLatestRelease,
        <String, Object>{},
      );

      expect(release, isNull);
    });
  });
}
