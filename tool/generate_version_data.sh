#!/bin/sh
# Writes lib/helpers/generated_app_version_data.dart from pubspec.yaml's name and
# version, already formatted. Run by tool/check.sh and tool/release.sh, so both
# write the same file.
set -e

cd "$(dirname "$0")/.."

APP_NAME=$(awk -F': *' '/^name:/{print $2; exit}' pubspec.yaml | tr -d '"' | xargs)
APP_VERSION_RAW=$(awk -F': *' '/^version:/{print $2; exit}' pubspec.yaml | tr -d '"' | xargs)
APP_VERSION=${APP_VERSION_RAW%%+*}

if [ "$APP_VERSION_RAW" = "$APP_VERSION" ]; then
	APP_BUILD_NUMBER='0'
else
	APP_BUILD_NUMBER=${APP_VERSION_RAW#*+}
fi

cat > lib/helpers/generated_app_version_data.dart << EOF
/// Auto-generated application metadata from \`pubspec.yaml\`.
///
/// This file is refreshed by \`tool/generate_version_data.sh\`.
abstract final class GeneratedAppVersionData {
  /// The pub package name from \`pubspec.yaml\`.
  static const String packageName = '${APP_NAME}';

  /// The semantic app version from \`pubspec.yaml\`.
  static const String version = '${APP_VERSION}';

  /// The build number extracted from \`pubspec.yaml\`.
  static const String buildNumber = '${APP_BUILD_NUMBER}';
}
EOF
