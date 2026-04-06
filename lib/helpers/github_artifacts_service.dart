import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:money/helpers/constants_helper.dart';
import 'package:money/helpers/shared_strings_helper.dart';

/// Service to fetch latest GitHub release artifacts
class GitHubArtifactsService {
  static const String _repoOwner = 'vteam-com';
  static const String _repoName = 'fMoney';
  static const String _apiBaseUrl = 'https://api.github.com';

  /// Fetches the latest release artifacts and falls back to workflow artifacts
  static Future<Map<String, String>> getLatestArtifactUrls() async {
    try {
      // First try to get the latest release
      final Map<String, String> releaseUrls = await _getLatestReleaseUrls();
      if (releaseUrls.isNotEmpty) {
        return releaseUrls;
      }

      // Fallback to workflow artifacts if no releases found
      return await _getWorkflowArtifactUrls();
    } catch (_) {
      // Return fallback URLs if both GitHub API calls fail
      return _getFallbackUrls();
    }
  }

  /// Gets URLs from the latest GitHub release
  static Future<Map<String, String>> _getLatestReleaseUrls() async {
    try {
      final http.Response response = await http.get(
        Uri.parse('$_apiBaseUrl/repos/$_repoOwner/$_repoName/releases/latest'),
        headers: <String, String>{
          'Accept': SharedStrings.githubApiAcceptV3Json,
          'User-Agent': 'fMoney-App',
        },
      );

      if (response.statusCode != Constants.httpStatusOk) {
        throw Exception('Failed to fetch latest release: ${response.statusCode}');
      }

      final Map<String, dynamic> releaseData = json.decode(response.body) as Map<String, dynamic>;
      final List<dynamic> assets = releaseData['assets'] as List<dynamic>? ?? <dynamic>[];

      final Map<String, String> artifactUrls = <String, String>{};

      for (final dynamic asset in assets) {
        final String name = asset['name'] as String;
        final String downloadUrl = asset['browser_download_url'] as String;

        // Map asset names to platforms
        if (name.contains(SharedStrings.platformKeyWindows)) {
          artifactUrls[SharedStrings.platformKeyWindows] = downloadUrl;
        } else if (name.contains(SharedStrings.platformKeyLinux)) {
          artifactUrls[SharedStrings.platformKeyLinux] = downloadUrl;
        } else if (name.contains(SharedStrings.platformKeyMacos)) {
          artifactUrls[SharedStrings.platformKeyMacos] = downloadUrl;
        }
      }

      return artifactUrls;
    } catch (_) {
      return <String, String>{};
    }
  }

  /// Gets URLs from workflow artifacts (fallback)
  static Future<Map<String, String>> _getWorkflowArtifactUrls() async {
    try {
      // Get the latest successful workflow run for main branch
      final http.Response workflowResponse = await http.get(
        Uri.parse(
          '$_apiBaseUrl/repos/$_repoOwner/$_repoName/actions/workflows/builds.yml/runs?branch=main&status=success&per_page=1',
        ),
        headers: <String, String>{
          'Accept': SharedStrings.githubApiAcceptV3Json,
          'User-Agent': 'fMoney-App',
        },
      );

      if (workflowResponse.statusCode != Constants.httpStatusOk) {
        throw Exception('Failed to fetch workflow runs: ${workflowResponse.statusCode}');
      }

      final Map<String, dynamic> workflowData = json.decode(workflowResponse.body) as Map<String, dynamic>;
      final List<dynamic> runs = workflowData['workflow_runs'] as List<dynamic>;

      if (runs.isEmpty) {
        throw Exception('No successful workflow runs found');
      }

      final dynamic latestRun = runs.first;
      final int runId = latestRun['id'] as int;

      // Get artifacts for this run
      final http.Response artifactsResponse = await http.get(
        Uri.parse('$_apiBaseUrl/repos/$_repoOwner/$_repoName/actions/runs/$runId/artifacts'),
        headers: <String, String>{
          'Accept': SharedStrings.githubApiAcceptV3Json,
          'User-Agent': 'fMoney-App',
        },
      );

      if (artifactsResponse.statusCode != Constants.httpStatusOk) {
        throw Exception('Failed to fetch artifacts: ${artifactsResponse.statusCode}');
      }

      final Map<String, dynamic> artifactsData = json.decode(artifactsResponse.body) as Map<String, dynamic>;
      final List<dynamic> artifacts = artifactsData['artifacts'] as List<dynamic>;

      final Map<String, String> artifactUrls = <String, String>{};

      for (final dynamic artifact in artifacts) {
        final String name = artifact['name'] as String;
        final String archiveDownloadUrl = artifact['archive_download_url'] as String;

        // Map artifact names to platforms
        if (name.contains(SharedStrings.platformKeyWindows)) {
          artifactUrls[SharedStrings.platformKeyWindows] = archiveDownloadUrl;
        } else if (name.contains(SharedStrings.platformKeyLinux)) {
          artifactUrls[SharedStrings.platformKeyLinux] = archiveDownloadUrl;
        } else if (name.contains(SharedStrings.platformKeyMacos)) {
          artifactUrls[SharedStrings.platformKeyMacos] = archiveDownloadUrl;
        }
      }

      return artifactUrls;
    } catch (_) {
      return <String, String>{};
    }
  }

  /// Gets fallback URLs
  static Map<String, String> _getFallbackUrls() {
    return <String, String>{
      SharedStrings.platformKeyWindows: 'https://money.vteam.com/downloads/mymoney-app-windows.zip',
      SharedStrings.platformKeyLinux: 'https://money.vteam.com/downloads/mymoney-app-linux.zip',
      SharedStrings.platformKeyMacos: 'https://money.vteam.com/downloads/mymoney-app-macos.zip',
    };
  }
}
