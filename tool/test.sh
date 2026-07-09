#!/bin/sh

tool/clean.sh

flutter test integration_test --coverage --coverage-path=coverage/lcov_integration.info -d macos --enable-impeller || exit 1

flutter test --coverage --coverage-path=coverage/lcov_units.info || exit 1

lcov -a coverage/lcov_integration.info -a coverage/lcov_units.info -o coverage/lcov.info

# Exclude generated localization files from coverage scoring.
if grep -q '^SF:lib/l10n/' coverage/lcov.info; then
	lcov --remove coverage/lcov.info 'lib/l10n/*' -o coverage/lcov.info
fi

if grep -q '^SF:.*/lib/l10n/' coverage/lcov.info; then
	lcov --remove coverage/lcov.info '*/lib/l10n/*' -o coverage/lcov.info
fi

genhtml --css-file coverage/genhtml.css -q coverage/lcov.info -o coverage/html > coverage/cc.txt

# keep the file cc.txt in git log, but also display it to the user
cat coverage/cc.txt

open coverage/html/index.html
