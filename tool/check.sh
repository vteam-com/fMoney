#!/bin/sh
echo --- Pub Get
flutter pub get > /dev/null || { echo "Pub get failed"; exit 1; }
echo --- Pub Upgrade
flutter pub upgrade > /dev/null
echo --- Pub Outdated
flutter pub outdated

# echo --- Generate Loc
# python3 tool/loc.py

echo --- Sort code
dart run tool/sort_source.dart

echo --- Format sources
dart format . | sed 's/^/    /'
dart fix --apply | sed 's/^/    /'

echo --- Analyze
flutter analyze lib test --no-pub | sed 's/^/    /'

echo --- Test
echo "    Running tests..."
flutter test --reporter=compact --no-pub

echo --- Graph Dependencies
tool/graph.sh | sed 's/^/    /'
