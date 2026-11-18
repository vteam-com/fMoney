import 'package:money/helpers/shared_strings_helper.dart';

/// A published GitHub release: its tag, its web page and the download URL of each desktop archive.
class GitHubRelease {
  /// Creates a release published under [tagName], shown at [pageUrl], with per-platform [assetUrls].
  const GitHubRelease({
    required this.assetUrls,
    required this.pageUrl,
    required this.tagName,
  });

  /// Reads a release from the GitHub REST API release JSON, keeping the assets whose
  /// name contains a platform key (for example `mymoney-app-macos.zip`).
  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final Map<String, String> assetUrls = <String, String>{};
    for (final dynamic asset in json['assets'] as List<dynamic>? ?? <dynamic>[]) {
      final String name = asset['name'] as String;
      final String downloadUrl = asset['browser_download_url'] as String;
      for (final String platformKey in _platformKeys) {
        if (name.contains(platformKey)) {
          assetUrls[platformKey] = downloadUrl;
          break;
        }
      }
    }
    return GitHubRelease(
      assetUrls: assetUrls,
      pageUrl: json['html_url'] as String? ?? '',
      tagName: json['tag_name'] as String? ?? '',
    );
  }

  /// Prefix of version tags, as in `v1.20.0`.
  static const String _tagPrefix = 'v';

  /// Platform keys looked for in asset names, in matching order.
  static const List<String> _platformKeys = <String>[
    SharedStrings.platformKeyWindows,
    SharedStrings.platformKeyLinux,
    SharedStrings.platformKeyMacos,
  ];

  /// Download URL of each platform's archive, keyed by the `SharedStrings.platformKey*` values.
  final Map<String, String> assetUrls;

  /// The release page on github.com.
  final String pageUrl;

  /// The git tag the release was published under, for example `v1.20.0`.
  final String tagName;

  /// The released version without the tag's leading `v`, for example `1.20.0`.
  String get version => tagName.startsWith(_tagPrefix) ? tagName.substring(_tagPrefix.length) : tagName;
}
