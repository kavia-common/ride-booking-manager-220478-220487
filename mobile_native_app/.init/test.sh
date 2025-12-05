#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/home/kavia/workspace/code-generation/ride-booking-manager-220478-220487/mobile_native_app"
cd "$WORKSPACE"
[ -f package.json ] || { echo 'ERROR: package.json missing; run scaffold first' >&2; exit 2; }
# Detect package manager
PKG_MANAGER="npm"
if [ -f yarn.lock ] && command -v yarn >/dev/null 2>&1; then PKG_MANAGER="yarn"; fi
# Check if jest listed in package.json
has_jest=$(node -e "const p=require('./package.json');console.log((p.devDependencies&&p.devDependencies.jest)||(p.dependencies&&p.dependencies.jest)?1:0)" || echo 0)
if [ "$has_jest" -ne 1 ]; then
  if [ "$PKG_MANAGER" = "yarn" ]; then
    yarn add --dev --silent jest@^29.0.0 || { echo 'ERROR: yarn add jest failed' >&2; exit 3; }
    # reconcile lockfile/node_modules
    yarn --silent --non-interactive || true
  else
    npm i --save-dev --no-audit --no-fund --silent jest@^29.0.0 || { echo 'ERROR: npm add jest failed' >&2; exit 4; }
    npm i --silent --no-audit --no-fund || true
  fi
fi
# Ensure minimal jest config file exists
if [ ! -f jest.config.js ]; then
  cat > jest.config.js <<'JCFG'
module.exports = { preset: 'react-native' };
JCFG
fi
# Ensure package.json has jest preset if missing
has_jest_config=$(node -e "const p=require('./package.json');console.log(p.jest?1:0)" || echo 0)
if [ "$has_jest_config" -ne 1 ]; then
  node -e "const fs=require('fs');const p=require('./package.json');p.jest=p.jest||{};p.jest.preset=p.jest.preset||'react-native';fs.writeFileSync('package.json',JSON.stringify(p,null,2))"
  # reconcile dependencies after package.json change
  if [ "$PKG_MANAGER" = "yarn" ]; then
    yarn --silent --non-interactive || true
  else
    npm i --silent --no-audit --no-fund || true
  fi
fi
mkdir -p __tests__ && cat > __tests__/dummy.test.js <<'JS'
test('dummy', () => expect(1+1).toBe(2));
JS
# Prefer local jest binary
if [ -x "node_modules/.bin/jest" ]; then
  ./node_modules/.bin/jest --colors --runInBand || { echo 'ERROR: jest (local) failed' >&2; exit 5; }
elif command -v jest >/dev/null 2>&1; then
  jest --colors --runInBand || { echo 'ERROR: jest (global) failed' >&2; exit 6; }
else
  # fallback to npx which will install if missing
  npx --yes jest --colors --runInBand || { echo 'ERROR: npx jest failed' >&2; exit 7; }
fi
