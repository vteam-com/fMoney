#!/bin/sh
set -e

# shellcheck source=tool/fcheck.env
. "$(dirname "$0")/fcheck.env"

echo --------------- PreStep Generate App Version Data
"$(dirname "$0")/generate_version_data.sh"

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
mkdir -p "$PWD/$FCHECK_PUB_CACHE"
export PUB_CACHE="$PWD/$FCHECK_PUB_CACHE"

# Install the pinned version into the isolated cache, then run it.
# Note: `dart pub cache exec` doesn't exist on all Dart SDK versions; `pub global run` does.
dart pub global activate fcheck "$FCHECK_VERSION" > /dev/null
dart pub global run fcheck --svg --fix --strict

echo --------------- Format sources
dart format .
dart fix --apply
