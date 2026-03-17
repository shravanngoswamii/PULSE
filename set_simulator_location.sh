#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# set_simulator_location.sh
# Continuously sets the booted iOS Simulator's GPS location to Indore, India.
# Runs in a loop so the location persists even if the simulator tries to revert.
#
# Usage:
#   chmod +x set_simulator_location.sh   # (first time only)
#   ./set_simulator_location.sh           # runs in foreground; Ctrl-C to stop
# ─────────────────────────────────────────────────────────────────────────────

LAT="22.820567"
LNG="75.942712"
CITY="Acropolis Institute (AITR), Indore, India"
INTERVAL=5   # re-apply every 5 seconds

# Find the first booted simulator UDID
UDID=$(xcrun simctl list devices booted | grep -E '\(Booted\)' | head -1 | grep -oE '[0-9A-F\-]{36}')

if [ -z "$UDID" ]; then
  echo "❌  No booted simulator found. Please launch a simulator first."
  exit 1
fi

echo "📍  Locking simulator $UDID to $CITY ($LAT, $LNG)"
echo "    Re-applying every ${INTERVAL}s. Press Ctrl-C to stop."

cleanup() {
  echo ""
  echo "🛑  Stopped location simulation."
  exit 0
}
trap cleanup SIGINT SIGTERM

while true; do
  xcrun simctl location "$UDID" set "$LAT,$LNG" 2>/dev/null
  sleep "$INTERVAL"
done
