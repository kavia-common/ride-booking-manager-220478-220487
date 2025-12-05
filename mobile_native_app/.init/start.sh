#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/ride-booking-manager-220478-220487/mobile_native_app"
cd "$WORKSPACE"
export CI=true NODE_ENV=development
LOG=/tmp/metro.log
# start metro in background and capture pid and pgid
npx react-native start --port 8081 >"$LOG" 2>&1 &
METRO_PID=$!
# small sleep to let process start
sleep 1
METRO_PGID=$(ps -o pgid= -p "$METRO_PID" | tr -d ' ' || echo "$METRO_PID")
cat > /tmp/metro.meta <<EOF
METRO_PID=$METRO_PID
METRO_PGID=$METRO_PGID
METRO_LOG=$LOG
EOF
printf "{\"started\":true,\"pid\":%s,\"pgid\":%s}\n" "$METRO_PID" "$METRO_PGID"
