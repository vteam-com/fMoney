#!/bin/sh

# rm -R ./build

flutter clean
flutter pub get
flutter pub upgrade
flutter pub outdated

rm test_output_sqlite.db
rm flutter_*.log