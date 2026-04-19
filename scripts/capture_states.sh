#!/usr/bin/env bash
# capture_states.sh — Drive the simulator through each seeded fixture state
# via the checklist://seed URL scheme, screenshot each, and assemble a diff
# folder at /tmp/checklist-diff/.
#
# Prereq: Checklist.app built + installed on the booted sim, DEBUG build.
#
# Usage: scripts/capture_states.sh

set -euo pipefail

OUT=/tmp/checklist-diff
mkdir -p "$OUT"

states=(empty oneList seededMulti historicalRuns nearCompleteRun)

for s in "${states[@]}"; do
  xcrun simctl openurl booted "checklist://seed/$s"
  sleep 2
  xcrun simctl io booted screenshot "$OUT/home-$s.png"
  sips -Z 1800 "$OUT/home-$s.png" >/dev/null
  echo "captured $s"
done

echo "Screenshots saved to $OUT"
