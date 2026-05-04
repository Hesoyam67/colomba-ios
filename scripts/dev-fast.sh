#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="all"

usage() {
  cat <<'USAGE'
Usage: scripts/dev-fast.sh [--build|--test]

Runs the fast SwiftPM validation loop used during day-to-day Colomba iOS work.

Options:
  --build   Build the root package and every local package.
  --test    Test the root package and every local package.
  --help    Show this help.

Non-macOS hosts intentionally fail unless ALLOW_SKIP_NON_DARWIN=1 is set.
USAGE
}

if [[ $# -gt 1 ]]; then
  usage >&2
  exit 64
fi

if [[ $# -eq 1 ]]; then
  case "$1" in
    --build) MODE="build" ;;
    --test) MODE="test" ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 64 ;;
  esac
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  if [[ "${ALLOW_SKIP_NON_DARWIN:-0}" == "1" ]]; then
    echo "Skipping Colomba SwiftPM loop outside macOS because ALLOW_SKIP_NON_DARWIN=1."
    exit 0
  fi
  echo "Colomba SwiftPM loop requires macOS/Xcode. Set ALLOW_SKIP_NON_DARWIN=1 to skip intentionally." >&2
  exit 78
fi

run_root() {
  local action="$1"
  echo "== swift ${action} ."
  (cd "$ROOT_DIR" && swift "$action")
}

run_packages() {
  local action="$1"
  local found=0
  for pkg in "$ROOT_DIR"/Packages/* "$ROOT_DIR"/Packages/Features/*; do
    if [[ -f "$pkg/Package.swift" ]]; then
      found=1
      echo "== swift ${action} ${pkg#$ROOT_DIR/}"
      (cd "$pkg" && swift "$action")
    fi
  done
  if [[ "$found" == "0" ]]; then
    echo "No local package manifests found."
  fi
}

run_builds() {
  run_root build
  run_packages build
}

run_tests() {
  run_root test
  run_packages test
}

case "$MODE" in
  build) run_builds ;;
  test) run_tests ;;
  all)
    run_builds
    run_tests
    ;;
esac
