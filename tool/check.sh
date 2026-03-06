#!/bin/sh
echo --------------- Pub Get
flutter pub get > /dev/null || { echo "Pub get failed"; exit 1; }

echo --------------- Pub Upgrade
flutter pub upgrade > /dev/null

echo --------------- Pub Outdated
flutter pub outdated

echo --------------- Generate Loc
python3 tool/loc.py

echo --------------- Analyze
flutter analyze lib test --no-pub | sed 's/^/    /'

echo --------------- Test
echo "    Running tests..."
flutter test --reporter=compact --no-pub

echo --- Generate Loc
python3 tool/loc.py

echo --------------- fCheck
# Use an ephemeral private directory for this session's fcheck installation
# (avoid contaminating the user's global pub cache and avoid version conflicts)
mkdir -p "$PWD/.dart_tool/fcheck_pub_cache"
export PUB_CACHE="$PWD/.dart_tool/fcheck_pub_cache"

# Install the pinned version into the isolated cache, then run it.
# Note: `dart pub cache exec` doesn't exist on all Dart SDK versions; `pub global run` does.
dart pub global activate fcheck 1.0.8 > /dev/null
dart pub global run fcheck --fix --svg --list full --exclude "**/app_localizations.dart"
# dart run ../fcheck/bin/fcheck.dart --fix --svg --svgfolder --list 100 ./lib/

echo --------------- Format sources
dart format . | sed 's/^/    /'
dart fix --apply | sed 's/^/    /'