#!/bin/sh
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
dart pub global activate fcheck 1.1.3 > /dev/null
dart pub global run fcheck --fix --svg

echo --------------- Format sources
dart format .
dart fix --apply