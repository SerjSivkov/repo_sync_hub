#!/usr/bin/env bash
# Regenerate macOS AppIcon.appiconset from assets/images/app_icon.png
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${ROOT}/assets/images/app_icon.png"
SET="${ROOT}/macos/Runner/Assets.xcassets/AppIcon.appiconset"

if [[ ! -f "$SRC" ]]; then
  echo "Missing source icon: $SRC" >&2
  exit 1
fi

mkdir -p "$SET"

gen() {
  local size="$1"
  local out="$2"
  sips -z "$size" "$size" "$SRC" --out "$out" >/dev/null
}

gen 16  "${SET}/app_icon_16.png"
gen 32  "${SET}/app_icon_32.png"
gen 64  "${SET}/app_icon_64.png"
gen 128 "${SET}/app_icon_128.png"
gen 256 "${SET}/app_icon_256.png"
gen 512 "${SET}/app_icon_512.png"
gen 1024 "${SET}/app_icon_1024.png"

echo "Updated AppIcon.appiconset in macos/Runner/Assets.xcassets/"
echo "Run: flutter clean && flutter run -d macos"
