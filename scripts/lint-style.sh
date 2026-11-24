#!/usr/bin/env bash
# Runs Mathlib's text-based style linters (`lake exe lint-style`) on every Lean file under src/,
# as .github/workflows/lint-style.yml does. Other arguments go to lint-style, so
# `scripts/lint-style.sh --fix` applies the fixes it knows. Known errors are listed in
# scripts/nolints-style.txt.
#
# lint-style reads module A.B from A/B.lean under the working directory, and it lints the
# modules that the root module it is given imports, if their names start like the root's. Our
# modules are under src/ and have no common root, so this makes one for the run: Src is a link
# to src/, and src/Src.lean imports every module as Src.<module>. In the output, Src/ is src/.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -e Src ]; then
  # On a case-insensitive file system, Src already is src.
  trap 'rm -f src/Src.lean' EXIT
else
  ln -s src Src
  trap 'rm -f Src src/Src.lean' EXIT
fi
find src -name '*.lean' ! -path src/Src.lean \
  | sed -e 's|^src/|import Src.|' -e 's|\.lean$||' -e 's|/|.|g' > src/Src.lean
lake exe lint-style "$@" Src
