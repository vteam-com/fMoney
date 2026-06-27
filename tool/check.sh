#!/bin/sh
set -e

generate_app_version_data() {
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
/// This file is refreshed by \`tool/check.sh\`.
abstract final class GeneratedAppVersionData {
	/// The pub package name from \`pubspec.yaml\`.
	static const String packageName = '${APP_NAME}';

	/// The semantic app version from \`pubspec.yaml\`.
	static const String version = '${APP_VERSION}';

	/// The build number extracted from \`pubspec.yaml\`.
	static const String buildNumber = '${APP_BUILD_NUMBER}';
}
EOF
}

echo --------------- PreStep Generate App Version Data
generate_app_version_data

echo --------------- Pub Get
flutter pub get > /dev/null || { echo "Pub get failed"; exit 1; }

echo --------------- Pub Upgrade
flutter pub upgrade > /dev/null

echo --------------- Pub Outdated
flutter pub outdated

echo --------------- Analyze
flutter analyze lib test --no-pub | sed 's/^/    /'

echo --------------- Test
echo "    Running tests..."
flutter test --reporter=compact --no-pub

echo --------------- fCheck
# Use an ephemeral private directory for this session's fcheck installation
# (avoid contaminating the user's global pub cache and avoid version conflicts)
mkdir -p "$PWD/.dart_tool/fcheck_pub_cache"
export PUB_CACHE="$PWD/.dart_tool/fcheck_pub_cache"

# Install the pinned version into the isolated cache, then run it.
# Note: `dart pub cache exec` doesn't exist on all Dart SDK versions; `pub global run` does.
dart pub global activate fcheck 1.4.1 > /dev/null
dart pub global run fcheck --svg --fix --strict

echo --------------- Format sources
dart format .
dart fix --apply
