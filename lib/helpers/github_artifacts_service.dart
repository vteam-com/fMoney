import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/github_release_model.dart';
import 'package:money/helpers/shared_strings_helper.dart';

/// Service to fetch latest GitHub release artifacts
class GitHubArtifactsService {
  /// User-Agent sent with every request to GitHub, which rejects requests without one.
  static const String userAgent = 'fMoney-App';

  /// Download URL of each desktop archive, used for every platform GitHub does not provide.
  static const Map<String, String> fallbackUrls = <String, String>{
    SharedStrings.platformKeyWindows: 'https://money.vteam.com/downloads/mymoney-app-windows.zip',
    SharedStrings.platformKeyLinux: 'https://money.vteam.com/downloads/mymoney-app-linux.zip',
    SharedStrings.platformKeyMacos: 'https://money.vteam.com/downloads/mymoney-app-macos.zip',
  };

  static const String _repoOwner = 'vteam-com';
  static const String _repoName = 'fMoney';
  static const String _apiBaseUrl = 'https://api.github.com';

  /// API path listing the latest successful build of the main branch.
  static const String _latestBuildRunsPath = 'actions/workflows/builds.yml/runs?branch=main&status=success&per_page=1';

  /// Returns the download URL of each desktop archive, keyed by the `SharedStrings.platformKey*` values:
  /// the latest release's archives, else the latest successful build's artifacts, and
  /// [fallbackUrls] for every platform neither provides.
  static Future<Map<String, String>> getLatestArtifactUrls() async {
    Map<String, String> urls = await _getLatestReleaseUrls();
    if (urls.isEmpty) {
      urls = await _getWorkflowArtifactUrls();
    }
    return <String, String>{...fallbackUrls, ...urls};
  }

  /// Fetches the latest published release, or null when GitHub can't be reached or answers with an error.
  static Future<GitHubRelease?> fetchLatestRelease() async {
    try {
      final Map<String, dynamic>? release = await _getJson('releases/latest');
      return release == null ? null : GitHubRelease.fromJson(release);
    } catch (_) {
      return null;
    }
  }

  /// GETs [path] under this repository's GitHub API URL and returns the decoded JSON object,
  /// or null when GitHub answers with an error status.
  static Future<Map<String, dynamic>?> _getJson(String path) async {
    final http.Response response = await http
        .get(
          Uri.parse('$_apiBaseUrl/repos/$_repoOwner/$_repoName/$path'),
          headers: <String, String>{
            'Accept': SharedStrings.githubApiAcceptV3Json,
            'User-Agent': userAgent,
          },
        )
        .timeout(Constants.httpRequestTimeout);

    if (response.statusCode != Constants.httpStatusOk) {
      return null;
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Gets URLs from the latest GitHub release
  static Future<Map<String, String>> _getLatestReleaseUrls() async =>
      (await fetchLatestRelease())?.assetUrls ?? <String, String>{};

  /// Gets the artifact URLs of the latest successful build of the main branch,
  /// or an empty map when GitHub can't be reached or has none.
  static Future<Map<String, String>> _getWorkflowArtifactUrls() async {
    try {
      final Map<String, dynamic>? workflowData = await _getJson(_latestBuildRunsPath);
      final List<dynamic> runs = workflowData?['workflow_runs'] as List<dynamic>? ?? <dynamic>[];
      if (runs.isEmpty) {
        return <String, String>{};
      }

      final int runId = runs.first['id'] as int;
      final Map<String, dynamic>? artifactsData = await _getJson('actions/runs/$runId/artifacts');

      final Map<String, String> artifactUrls = <String, String>{};
      for (final dynamic artifact in artifactsData?['artifacts'] as List<dynamic>? ?? <dynamic>[]) {
        final String? platformKey = GitHubRelease.platformKeyForAssetName(artifact['name'] as String);
        if (platformKey != null) {
          artifactUrls[platformKey] = artifact['archive_download_url'] as String;
        }
      }
      return artifactUrls;
    } catch (_) {
      return <String, String>{};
    }
  }
}
