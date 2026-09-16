#!/bin/sh

set -eu

PROJECT_ROOT=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
TEST_ROOT=${TMPDIR:-/tmp}/set-pre-commit-profile-validation.$$

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup 0
trap 'exit 1' HUP INT TERM
mkdir -p "$TEST_ROOT"

for profile in code python; do
    profile_root="$TEST_ROOT/$profile"
    mkdir -p "$profile_root"
    "$PROJECT_ROOT/bin/set-pre-commit" render "$profile" >"$profile_root/hk.pkl"
    (cd "$profile_root" && hk validate)
done

printf 'All profiles are valid.\n'