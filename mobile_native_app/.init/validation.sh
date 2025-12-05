#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/ride-booking-manager-220478-220487/mobile_native_app"
cd "$WORKSPACE"
export CI=true NODE_ENV=development
LOG=/tmp/metro.log
# start metro and ensure cleanup on EXIT
npx react-native start --port 8081 >"$LOG" 2>&1 &
METRO_PID=$!
sleep 1
METRO_PGID=$(ps -o pgid= -p "$METRO_PID" | tr -d ' ' || echo "$METRO_PID")
cleanup() {
  if ps -p "$METRO_PID" >/dev/null 2>&1; then kill -TERM "$METRO_PID" 2>/dev/null || true; fi
  if [ -n "$METRO_PGID" ]; then kill -TERM -"$METRO_PGID" 2>/dev/null || true; fi
  wait "$METRO_PID" 2>/dev/null || true
}
trap cleanup EXIT
# poll readiness
RETRIES=60
READY=0
for i in $(seq 1 $RETRIES); do
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 http://127.0.0.1:8081/status || true)
  if [ "$http_code" = "200" ]; then READY=1; break; fi
  # log heuristics
  if grep -Ei "metro ready|running.*metro|bundle.*asset|loading .*index" "$LOG" 2>/dev/null | grep -qi .; then READY=1; break; fi
  sleep 1
done
if [ "$READY" -ne 1 ]; then
  echo 'ERROR: Metro failed to become ready; tailing log' >&2
  tail -n 200 "$LOG" >&2 || true
  exit 2
fi
APK_PATH="$WORKSPACE/android/app/build/outputs/apk/debug/app-debug.apk"
APK_BUILT=false
# decide whether to attempt APK build
if [ -d android ] && [ -f android/gradlew ]; then
  if [ -d "/opt/android-sdk/platforms" ] && [ -d "/opt/android-sdk/build-tools" ]; then
    SDKMANAGER="/opt/android-sdk/cmdline-tools/latest/bin/sdkmanager"
    if [ -x "$SDKMANAGER" ]; then
      yes | "$SDKMANAGER" --licenses --sdk_root="/opt/android-sdk" >/dev/null 2>&1 || true
    fi
    (cd android && chmod +x gradlew && ./gradlew assembleDebug --no-daemon -q) || { echo 'ERROR: gradle assembleDebug failed' >&2; exit 3; }
    [ -f "$APK_PATH" ] && APK_BUILT=true
  else
    echo 'INFO: Android SDK platforms/build-tools missing; skipping APK build' >&2
  fi
fi
# emit JSON evidence
apk_json=false
if [ "$APK_BUILT" = true ]; then apk_json=true; fi
printf '{"metro_status":"ok","apk_exists":%s}\n' "$apk_json"
