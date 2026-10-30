#!/usr/bin/env bash
# Assembles custom-build from upstream and the branches waiting to be merged, then pushes it to the fork.
# GitHub Actions (custom-build workflow) runs the tests and, for a tag, publishes the phar in a release.
# Usage: ./build.sh             assembles and pushes custom-build (tests only)
#        ./build.sh <version>   same, then creates and pushes the v<version> tag (e.g. ./build.sh 8.0.5-custom.2)
set -euo pipefail

# Branches included in the build, in cherry-pick order
BRANCHES=(
    feature/release-version
    config-array-inter
    shared-populate
    fix-local-archive-sentry
)

VERSION=${1:-}

git fetch upstream
git switch master
git merge --ff-only upstream/master

git switch custom
git rebase master

for branch in "${BRANCHES[@]}"; do
    git rebase master "$branch"
done

git switch -C custom-build custom
for branch in "${BRANCHES[@]}"; do
    git cherry-pick -x "master..$branch"
done
git switch custom

git push origin master
git push --force-with-lease origin custom custom-build "${BRANCHES[@]}"

if [ -n "$VERSION" ]; then
    # No -f: a published tag matches a release, it must not move
    git tag "v$VERSION" custom-build
    git push origin "v$VERSION"
fi
