#!/bin/sh

# rm -R ./build

# Remove CocoaPods artifacts
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks
# macOS plugins still require CocoaPods (no SPM support yet)
rm -rf macos/Pods macos/Podfile.lock macos/.symlinks

flutter clean
flutter pub get
flutter pub upgrade
flutter pub outdated

rm test_output_sqlite.db
rm flutter_*.log