#!/bin/bash
# Releases fMoney: sets the new version in pubspec.yaml and in the version the
# app reports, adds the release to CHANGELOG.md (one line per commit since the
# last release), checks and builds the code, then commits and pushes it. The
# push to main runs the "Flutter Desktop Build" workflow, which sees the new
# version, builds macOS, Windows and Linux, and publishes them as the GitHub
# release v<version> (creating that tag) with this CHANGELOG entry as notes.
#
# Usage: tool/release.sh <major|minor|patch|X.Y.Z>
#   patch  1.2.3 -> 1.2.4      minor  1.2.3 -> 1.3.0
#   major  1.2.3 -> 2.0.0      X.Y.Z  that exact version
# A build number (after a +) in pubspec.yaml goes up by one on every release.

set -euo pipefail

cd "$(dirname "$0")/.."
# shellcheck source=tool/fcheck.env
. tool/fcheck.env

RELEASE_BRANCH="main"
REMOTE="origin"
PUBSPEC="pubspec.yaml"
CHANGELOG="CHANGELOG.md"
# The version the app reports; the workflow refuses a release where it differs
VERSION_DATA="lib/helpers/generated_app_version_data.dart"
# The commits that only set a version, left out of the changelog
RELEASE_COMMIT='^Release v'
WORKFLOW_URL="https://github.com/vteam-com/fMoney/actions/workflows/builds.yml"

fail() {
	echo "Release stopped: $*" >&2
	exit 1
}

usage() {
	sed -n '/^# Usage:/,/^$/s/^# \{0,1\}//p' "$0" >&2
	exit 1
}

# Escapes the Markdown of each line outside its `code` spans, so a <tag>,
# a * or a \ in a commit subject shows as written
markdown_text() {
	awk -F'`' -v OFS='`' '{ for (i = 1; i <= NF; i += 2) gsub(/[\\<*]/, "\\\\&", $i); print }'
}

[ $# -eq 1 ] || usage

# --- The new version ----------------------------------------------------
current="$(sed -n 's/^version: *//p' "$PUBSPEC")"
[ -n "$current" ] || fail "no version in $PUBSPEC"
current_name="${current%%+*}"
IFS=. read -r major minor patch <<<"$current_name"

case "$1" in
	major) version="$((major + 1)).0.0" ;;
	minor) version="$major.$((minor + 1)).0" ;;
	patch) version="$major.$minor.$((patch + 1))" ;;
	[0-9]*.[0-9]*.[0-9]*)
		[[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || usage
		version="$1"
		;;
	*) usage ;;
esac
# fMoney's version has no build number; one that is there goes up by one
build="0"
full_version="$version"
if [[ "$current" == *+* ]]; then
	build="$((${current#*+} + 1))"
	full_version="$version+$build"
fi
tag="v$version"
previous_tag="v$current_name"

# --- The repository is ready ----------------------------------------------
[ "$(git branch --show-current)" = "$RELEASE_BRANCH" ] ||
	fail "releases are made from $RELEASE_BRANCH"
[ -z "$(git status --porcelain)" ] ||
	fail "commit or stash your changes first"
[ -f "$CHANGELOG" ] || fail "no $CHANGELOG"
git fetch --quiet --tags "$REMOTE" "$RELEASE_BRANCH"
[ "$(git rev-parse HEAD)" = "$(git rev-parse "$REMOTE/$RELEASE_BRANCH")" ] ||
	fail "$RELEASE_BRANCH differs from $REMOTE/$RELEASE_BRANCH: pull or push first"

# The workflow tags each version it releases, so the tags tell what shipped
[ -z "$(git ls-remote --tags "$REMOTE" "refs/tags/$tag")" ] ||
	fail "$tag is already released on $REMOTE"

# --- The changelog ----------------------------------------------------------
git rev-parse --quiet --verify "refs/tags/$previous_tag" >/dev/null ||
	fail "no tag $previous_tag: $PUBSPEC's version $current_name is not released yet (see $WORKFLOW_URL)"
git merge-base --is-ancestor "$previous_tag" HEAD ||
	fail "$previous_tag is not in $RELEASE_BRANCH's history"
changes="$(git log --no-merges --format='%s' "$previous_tag..HEAD" |
	{ grep -v "$RELEASE_COMMIT" || true; } | markdown_text | sed 's/^/- /')"
[ -n "$changes" ] || fail "nothing to release: no commits since $previous_tag"
# The heading the workflow looks for to write the release notes
section="## [version $version] $(date +%Y-%m-%d)

$changes"

printf '%s\n\n' "$section"
printf 'Release %s -> %s with this %s entry? [y/N] ' "$current" "$full_version" "$CHANGELOG"
read -r answer
[[ "$answer" =~ ^[Yy]$ ]] || fail "cancelled"

# --- Set the version and the changelog, then check and build ---------------
# Until the commit, any failure puts the three files back as they were
trap 'git checkout --quiet -- "$PUBSPEC" "$CHANGELOG" "$VERSION_DATA"' EXIT
sed -i.bak "s/^version: .*/version: $full_version/" "$PUBSPEC"
rm "$PUBSPEC.bak"
sed -i.bak \
	-e "s/\(static const String version = \)'[^']*';/\1'$version';/" \
	-e "s/\(static const String buildNumber = \)'[^']*';/\1'$build';/" \
	"$VERSION_DATA"
rm "$VERSION_DATA.bak"
grep -q "version = '$version';" "$VERSION_DATA" ||
	fail "could not set the version in $VERSION_DATA"
# The new release goes above the one before, under the file's title
SECTION="$section" awk '
	!added && /^## / { print ENVIRON["SECTION"]; print ""; added = 1 }
	{ print }
	END { if (!added) { print ""; print ENVIRON["SECTION"] } }
' "$CHANGELOG" >"$CHANGELOG.new"
mv "$CHANGELOG.new" "$CHANGELOG"

echo "--- Pub Get"
flutter pub get >/dev/null
echo "--- Analyze"
flutter analyze lib test --no-pub
echo "--- Test"
flutter test --no-pub --reporter=compact
echo "--- fCheck"
mkdir -p "$FCHECK_PUB_CACHE"
PUB_CACHE="$PWD/$FCHECK_PUB_CACHE" dart pub global activate fcheck "$FCHECK_VERSION" >/dev/null
PUB_CACHE="$PWD/$FCHECK_PUB_CACHE" dart pub global run fcheck --strict
echo "--- Build macOS"
flutter build macos --release

others="$(git status --porcelain -- ":(exclude)$PUBSPEC" ":(exclude)$CHANGELOG" ":(exclude)$VERSION_DATA")"
[ -z "$others" ] ||
	fail "the checks changed more files than $PUBSPEC, $CHANGELOG and $VERSION_DATA: $(echo "$others" | tr '\n' ' ')"

# --- Commit and push ---------------------------------------------------------
git commit --quiet -m "Release $tag" -- "$PUBSPEC" "$CHANGELOG" "$VERSION_DATA"
trap - EXIT
git push "$REMOTE" "$RELEASE_BRANCH" ||
	fail "push failed; the release is committed here, retry with: git push $REMOTE $RELEASE_BRANCH"

echo "Pushed $tag: the Flutter Desktop Build workflow now builds and publishes it"
echo "$WORKFLOW_URL"
