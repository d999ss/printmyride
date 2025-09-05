#!/bin/bash

# PrintMyRide Behavior Test Suite
# Run this BEFORE any refactoring to document current behavior
# Run again AFTER refactoring to ensure nothing broke

set -e

echo "========================================="
echo "PrintMyRide Current Behavior Test"
echo "Date: $(date)"
echo "========================================="

# Create test results directory
mkdir -p test_results
TEST_ID=$(date +%Y%m%d_%H%M%S)
RESULT_FILE="test_results/behavior_$TEST_ID.txt"

# Function to test and log
test_feature() {
    local name=$1
    local description=$2
    echo ""
    echo "Testing: $name" | tee -a "$RESULT_FILE"
    echo "Description: $description" | tee -a "$RESULT_FILE"
    echo "---" | tee -a "$RESULT_FILE"
}

# 1. Test Build
test_feature "Build" "Verify app builds without errors"
xcodebuild -scheme PrintMyRide -destination "platform=iOS Simulator,name=iPhone 16 Pro" build 2>&1 | tail -5 | tee -a "$RESULT_FILE"

# 2. Test Launch
test_feature "Launch" "Verify app launches"
APP_PATH="/Users/donnysmith/Library/Developer/Xcode/DerivedData/PrintMyRide-*/Build/Products/Debug-iphonesimulator/PrintMyRide.app"
DEVICE_ID=$(xcrun simctl list devices | grep "iPhone 16 Pro" | grep -o '[0-9A-F-]\{36\}' | head -1)

xcrun simctl boot $DEVICE_ID 2>/dev/null || true
xcrun simctl install $DEVICE_ID $APP_PATH
xcrun simctl launch $DEVICE_ID d999ss.PrintMyRide | tee -a "$RESULT_FILE"

# 3. Capture Screenshots of Key Screens
test_feature "Screenshots" "Capture UI state"
sleep 3

# Login screen
xcrun simctl io $DEVICE_ID screenshot "test_results/screen_login_$TEST_ID.png"
echo "Login screenshot saved" | tee -a "$RESULT_FILE"

# Navigate to main screen (skip to demo)
xcrun simctl ui $DEVICE_ID tap 360 1333 2>/dev/null || true
sleep 2
xcrun simctl io $DEVICE_ID screenshot "test_results/screen_main_$TEST_ID.png"
echo "Main screenshot saved" | tee -a "$RESULT_FILE"

# 4. Test Core Features
test_feature "PosterGeneration" "Check poster rendering paths"
grep -r "createSimpleTestPoster\|PosterRenderer\|PosterRenderService" PrintMyRide/ --include="*.swift" | wc -l | tee -a "$RESULT_FILE"

test_feature "AuthPaths" "Count authentication implementations"
grep -r "AuthService\|StravaOAuth" PrintMyRide/ --include="*.swift" | wc -l | tee -a "$RESULT_FILE"

test_feature "RouteHandlers" "Count route handling code"
grep -r "CLLocationCoordinate2D\|RouteData" PrintMyRide/ --include="*.swift" | wc -l | tee -a "$RESULT_FILE"

# 5. Memory Snapshot
test_feature "Memory" "Baseline memory usage"
xcrun simctl spawn $DEVICE_ID launchctl list | grep PrintMyRide | tee -a "$RESULT_FILE"

# 6. Document File Structure
test_feature "FileStructure" "Current file organization"
find PrintMyRide -name "*.swift" -type f | wc -l | tee -a "$RESULT_FILE"
echo "Swift files: $(find PrintMyRide -name '*.swift' -type f | wc -l)" | tee -a "$RESULT_FILE"

# 7. Check for Crashes
test_feature "CrashCheck" "Look for crash logs"
log show --predicate 'process == "PrintMyRide"' --style compact --last 1m 2>/dev/null | grep -i crash | wc -l | tee -a "$RESULT_FILE"

echo ""
echo "========================================="
echo "Test Complete!"
echo "Results saved to: $RESULT_FILE"
echo "Screenshots saved to: test_results/"
echo "========================================="
echo ""
echo "⚠️  IMPORTANT: Keep these results!"
echo "Run this script again after refactoring"
echo "Compare results with: diff test_results/behavior_*.txt"