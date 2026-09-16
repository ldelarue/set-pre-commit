#!/bin/sh

set -eu

PROJECT_ROOT=$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)
CLI="$PROJECT_ROOT/bin/set-pre-commit"
TEST_ROOT=${TMPDIR:-/tmp}/set-pre-commit-tests.$$
REAL_PATH=$PATH

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup 0
trap 'exit 1' HUP INT TERM
mkdir -p "$TEST_ROOT"

mkdir -p "$TEST_ROOT/bin"
cat >"$TEST_ROOT/bin/mise" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$MISE_LOG"
exit "${MISE_EXIT_CODE:-0}"
EOF
chmod +x "$TEST_ROOT/bin/mise"
export PATH="$TEST_ROOT/bin:$REAL_PATH"
export MISE_LOG="$TEST_ROOT/mise.log"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_contains() {
    file=$1
    text=$2
    grep -F "$text" "$file" >/dev/null || fail "$file does not contain: $text"
}

new_repository() {
    name=$1
    repository="$TEST_ROOT/$name"
    mkdir -p "$repository"
    git -C "$repository" init -q
    printf '%s\n' "$repository"
}

code_repository=$(new_repository code)
(cd "$code_repository" && "$CLI" init code >/dev/null)
assert_contains "$code_repository/hk.pkl" '["commit-msg"]'
assert_contains "$code_repository/hk.pkl" 'Builtins.check_conventional_commit'
assert_contains "$MISE_LOG" 'x hk@2.0.1 -- hk validate'
assert_contains "$MISE_LOG" 'use -y hk@2.0.1'
assert_contains "$MISE_LOG" 'exec -- hk install --mise'

python_repository=$(new_repository python)
(cd "$python_repository" && "$CLI" init python >/dev/null)
assert_contains "$python_repository/hk.pkl" 'Builtins.ruff'
assert_contains "$python_repository/hk.pkl" 'Builtins.ruff_format'
assert_contains "$python_repository/hk.pkl" 'Builtins.ty'
assert_contains "$python_repository/hk.pkl" '["pytest"]'
assert_contains "$python_repository/hk.pkl" '["commit-msg"]'
assert_contains "$python_repository/hk.pkl" '"pyproject.toml"'

(cd "$python_repository" && "$CLI" switch code >/dev/null)
assert_contains "$python_repository/hk.pkl" 'Builtins.check_conventional_commit'
if grep -F 'Builtins.ruff' "$python_repository/hk.pkl" >/dev/null; then
    fail "python checks remain after switching to code"
fi
assert_contains "$MISE_LOG" 'exec -- hk uninstall'

(cd "$python_repository" && "$CLI" switch code >/dev/null)

unmanaged_repository=$(new_repository unmanaged-switch)
printf 'custom\n' >"$unmanaged_repository/hk.pkl"
if (cd "$unmanaged_repository" && "$CLI" switch code >/dev/null 2>&1); then
    fail "an unmanaged hk.pkl was replaced"
fi
[ "$(cat "$unmanaged_repository/hk.pkl")" = custom ] || fail "unmanaged hk.pkl was modified"

"$CLI" render code >"$TEST_ROOT/rendered-code.pkl"
cmp "$code_repository/hk.pkl" "$TEST_ROOT/rendered-code.pkl" >/dev/null ||
    fail "rendered and initialized code profiles differ"

conflict_repository=$(new_repository conflict)
printf 'existing\n' >"$conflict_repository/hk.pkl"
if (cd "$conflict_repository" && "$CLI" init code >/dev/null 2>&1); then
    fail "existing hk.pkl was accepted"
fi
[ "$(cat "$conflict_repository/hk.pkl")" = existing ] || fail "existing hk.pkl was modified"

local_conflict_repository=$(new_repository local-conflict)
printf 'existing\n' >"$local_conflict_repository/hk.local.pkl"
if (cd "$local_conflict_repository" && "$CLI" init code >/dev/null 2>&1); then
    fail "existing hk.local.pkl was accepted"
fi
[ ! -e "$local_conflict_repository/hk.pkl" ] || fail "config was written beside hk.local.pkl"

hook_repository=$(new_repository hook-conflict)
printf '#!/bin/sh\n' >"$hook_repository/.git/hooks/commit-msg"
if (cd "$hook_repository" && "$CLI" init code >/dev/null 2>&1); then
    fail "existing commit-msg hook was accepted"
fi
[ ! -e "$hook_repository/hk.pkl" ] || fail "config was written despite a hook conflict"

failed_repository=$(new_repository failed-validation)
if (cd "$failed_repository" && MISE_EXIT_CODE=1 "$CLI" init code >/dev/null 2>&1); then
    fail "failed hk validation was accepted"
fi
[ ! -e "$failed_repository/hk.pkl" ] || fail "config was retained after validation failure"

if (cd "$TEST_ROOT" && "$CLI" init code >/dev/null 2>&1); then
    fail "execution outside a Git repository succeeded"
fi

printf 'All tests passed.\n'
