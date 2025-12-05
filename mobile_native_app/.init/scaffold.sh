#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/ride-booking-manager-220478-220487/mobile_native_app"
mkdir -p "$WORKSPACE" && cd "$WORKSPACE"
if [ ! -f package.json ]; then
  tmpdir=$(mktemp -d)
  # ensure rsync present
  command -v rsync >/dev/null 2>&1 || (sudo apt-get update -q && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q rsync >/dev/null)
  # run npx react-native init in tempdir; do not suppress stderr so failures are visible
  npx react-native init temp_mobile_app --npm --directory "$tmpdir" || { rc=$?; rm -rf "$tmpdir"; echo 'ERROR: react-native init failed' >&2; exit $rc; }
  if [ -d "$tmpdir/temp_mobile_app" ]; then
    src="$tmpdir/temp_mobile_app/"
  else
    src="$tmpdir/"
  fi
  # rsync copy while excluding node_modules to avoid large copies
  rsync -a --exclude='node_modules' "$src" "$WORKSPACE/" || { echo 'ERROR: rsync copy failed' >&2; rm -rf "$tmpdir"; exit 5; }
  rm -rf "$tmpdir"
fi
[ -f "$WORKSPACE/package.json" ] || { echo 'ERROR: package.json missing after scaffold' >&2; exit 2; }
# Safely add start/android scripts using Node while preserving existing scripts
node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync('package.json','utf8'));p.scripts=p.scripts||{};if(!p.scripts.start)p.scripts.start='react-native start';if(!p.scripts.android)p.scripts.android='react-native run-android --no-packager';fs.writeFileSync('package.json',JSON.stringify(p,null,2));"
# create lightweight file-based mock config
mkdir -p "$WORKSPACE/mocks" && cat > "$WORKSPACE/mocks/mock-config.json" <<'JSON'
{ "useMock": true, "mockServer": "file" }
JSON
