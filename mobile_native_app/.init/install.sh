#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/ride-booking-manager-220478-220487/mobile_native_app"
cd "$WORKSPACE"
[ -f package.json ] || { echo 'ERROR: package.json missing; run scaffold first' >&2; exit 2; }
# Print versions and warn if Node <16 (common RN reqs may vary)
node_v=$(node -v 2>/dev/null || echo "none")
npm_v=$(npm -v 2>/dev/null || echo "none")
# yarn is preinstalled in image but check path
yarn_v=$(command -v yarn >/dev/null 2>&1 && yarn -v 2>/dev/null || echo "none")
echo "NODE=$node_v NPM=$npm_v YARN=$yarn_v" >&2
if [[ "$node_v" != none ]]; then
  vnum=${node_v#v}
  maj=${vnum%%.*}
  if [ "${maj:-0}" -lt 16 ]; then
    echo 'WARN: Node major version <16 may be incompatible with some React Native templates' >&2
  fi
fi
# Ensure CI env for package managers
export CI=true
# Choose installer based on lockfiles and availability
if [ -f yarn.lock ] && command -v yarn >/dev/null 2>&1; then
  yarn --network-timeout 60000 --silent --non-interactive || { echo 'ERROR: yarn install failed' >&2; exit 3; }
elif [ -f package-lock.json ]; then
  npm ci --no-audit --no-fund --prefer-offline --silent || { echo 'ERROR: npm ci failed' >&2; exit 4; }
else
  if command -v yarn >/dev/null 2>&1; then
    yarn --network-timeout 60000 --silent --non-interactive || { echo 'ERROR: yarn install failed' >&2; exit 3; }
  else
    npm i --no-audit --no-fund --silent || { echo 'ERROR: npm install failed' >&2; exit 4; }
  fi
fi
# If package.json changed externally, run a reconcile install pass (idempotent)
# Detect if node_modules missing or package.json newer than node_modules
if [ ! -d node_modules ] || [ "$(stat -c %Y package.json)" -gt "$(stat -c %Y node_modules 2>/dev/null || echo 0)" ]; then
  if [ -f yarn.lock ] && command -v yarn >/dev/null 2>&1; then
    yarn --network-timeout 60000 --silent --non-interactive || { echo 'ERROR: yarn reconcile failed' >&2; exit 5; }
  elif [ -f package-lock.json ]; then
    npm ci --no-audit --no-fund --prefer-offline --silent || { echo 'ERROR: npm ci reconcile failed' >&2; exit 6; }
  else
    if command -v yarn >/dev/null 2>&1; then
      yarn --network-timeout 60000 --silent --non-interactive || { echo 'ERROR: yarn reconcile failed' >&2; exit 5; }
    else
      npm i --no-audit --no-fund --silent || { echo 'ERROR: npm reconcile failed' >&2; exit 6; }
    fi
  fi
fi
# If android/gradlew missing, warn (do not install system gradle)
if [ -d android ] && [ ! -f android/gradlew ]; then
  echo 'WARN: android/gradlew not present. APK build will be skipped in validation unless gradlew is added.' >&2
fi
# Validate installed binaries are on PATH
command -v node >/dev/null 2>&1 || { echo 'ERROR: node not available on PATH' >&2; exit 7; }
command -v npm >/dev/null 2>&1 || { echo 'ERROR: npm not available on PATH' >&2; exit 8; }
# yarn optional
if command -v yarn >/dev/null 2>&1; then
  : # yarn present
fi
