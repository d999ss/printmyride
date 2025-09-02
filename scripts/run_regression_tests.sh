#!/usr/bin/env bash
set -euo pipefail

SCHEME="PrintMyRide"
DEVICE="platform=iOS Simulator,name=iPhone 16 Pro"
OUT="./build/regression-test-results"

mkdir -p "$OUT"

echo "🚀 Running automated regression tests..."

xcodebuild \
  -project PrintMyRide.xcodeproj \
  -scheme "$SCHEME" \
  -destination "$DEVICE" \
  -only-testing:PrintMyRideUITests/RegressionTests \
  -resultBundlePath "$OUT/result-bundle" \
  test | xcpretty --report junit --output "$OUT/results.xml"

echo "✅ Tests complete. Results in $OUT"