#!/usr/bin/env bash
# Release-сборка Repo Sync Hub (по умолчанию — macOS).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

read_version() {
  grep '^version:' pubspec.yaml | awk '{print $2}'
}

reject_debug_args() {
  for arg in "$@"; do
    case "$arg" in
      --debug|debug)
        echo "ERROR: Debug build is not allowed. Use --release." >&2
        exit 1
        ;;
      --profile|profile)
        echo "ERROR: Profile build is not allowed for release artifacts." >&2
        exit 1
        ;;
    esac
  done
}

APP_VERSION="$(read_version)"
PLATFORM="${1:-macos}"
shift || true
reject_debug_args "$@"

echo "Building Repo Sync Hub ${APP_VERSION} (${PLATFORM}) in --release mode"

case "$PLATFORM" in
  macos)
    flutter pub get
    # shellcheck source=scripts/macos_nosign.sh
    source "${ROOT}/scripts/macos_nosign.sh"
    flutter build macos --release "$@"
    ;;
  windows)
    flutter pub get
    flutter build windows --release "$@"
    ;;
  *)
    echo "Unknown platform: $PLATFORM (supported: macos, windows)" >&2
    exit 1
    ;;
esac

echo "Done: ${PLATFORM} built with flutter build --release"
