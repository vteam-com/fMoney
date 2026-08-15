#!/bin/sh

tool/clean.sh

flutter test integration_test --coverage --coverage-path=coverage/lcov_integration.info -d macos --enable-impeller || exit 1

flutter test --coverage --coverage-path=coverage/lcov_units.info || exit 1

# Flutter emits FNF:0/FNH:0 (line coverage only), which lcov 2.x treats as a
# fatal "empty" error; demote it so the merge can complete.
lcov --ignore-errors empty -a coverage/lcov_integration.info -a coverage/lcov_units.info -o coverage/lcov.info || exit 1

# Exclude generated localization files from coverage scoring.
if grep -q '^SF:lib/l10n/' coverage/lcov.info; then
	lcov --ignore-errors empty --remove coverage/lcov.info 'lib/l10n/*' -o coverage/lcov.info || exit 1
fi

if grep -q '^SF:.*/lib/l10n/' coverage/lcov.info; then
	lcov --ignore-errors empty --remove coverage/lcov.info '*/lib/l10n/*' -o coverage/lcov.info || exit 1
fi

genhtml --css-file coverage/genhtml.css -q coverage/lcov.info -o coverage/html > coverage/cc.txt

# keep the file cc.txt in git log, but also display it to the user
cat coverage/cc.txt

open coverage/html/index.html
