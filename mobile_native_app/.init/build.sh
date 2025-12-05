#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/ride-booking-manager-220478-220487/mobile_native_app"
cd "$WORKSPACE"
APK_PATH="$WORKSPACE/android/app/build/outputs/apk/debug/app-debug.apk"
if [ ! -d android ] || [ ! -f android/gradlew ]; then
  printf '{"apk_built":false,"reason":"no_android_project"}\n'
  exit 0
fi
# ensure sdkmanager exists before license acceptance
SDK_ROOT="/opt/android-sdk"
SDKMANAGER="$SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
if [ -x "$SDKMANAGER" ]; then
  yes | "$SDKMANAGER" --licenses --sdk_root="$SDK_ROOT" >/dev/null 2>&1 || true
fi
# attempt assembleDebug
(cd android && chmod +x gradlew && ./gradlew assembleDebug --no-daemon -q) || { printf '{"apk_built":false,"reason":"gradle_failed"}\n' >&2; exit 1; }
if [ -f "$APK_PATH" ]; then
  printf '{"apk_built":true,"apk_path":"%s"}\n' "$APK_PATH"
else
  printf '{"apk_built":false,"reason":"apk_missing"}\n'
fi
