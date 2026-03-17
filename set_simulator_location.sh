#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# set_simulator_location.sh
# Sets the booted iOS Simulator's GPS location to Indore, India.
# Run this once after launching the simulator, before `flutter run`.
#
# Usage:
#   chmod +x set_simulator_location.sh   # (first time only)
#   ./set_simulator_location.sh
# ─────────────────────────────────────────────────────────────────────────────

LAT="22.820567"
LNG="75.942712"
CITY="Acropolis Institute (AITR), Indore, India"

# Find the first booted simulator UDID
UDID=$(xcrun simctl list devices booted | grep -E '\(Booted\)' | head -1 | grep -oE '[0-9A-F\-]{36}')

if [ -z "$UDID" ]; then
  echo "❌  No booted simulator found. Please launch a simulator first."
  exit 1
fi

echo "📍  Setting location of simulator $UDID → $CITY ($LAT, $LNG)"
xcrun simctl location "$UDID" set "$LAT,$LNG"

if [ $? -eq 0 ]; then
  echo "✅  Done! The simulator GPS is now set to $CITY."
  echo "    Hot-restart the app (press R in the flutter run terminal) to pick up the new location."
else
  echo "❌  Failed to set location. Make sure Xcode command-line tools are installed."
fi
