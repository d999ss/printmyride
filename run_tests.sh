#!/bin/bash

# PMR Test Runner Script
# Usage: ./run_tests.sh [all|unit|ui|snapshot|links]

set -e

SCHEME="PrintMyRide"
DESTINATION="platform=iOS Simulator,name=iPhone 16 Pro"

function run_all_tests() {
    echo "🧪 Running all PMR tests..."
    xcodebuild -scheme "$SCHEME" \
               -destination "$DESTINATION" \
               -quiet \
               test || true
}

function run_unit_tests() {
    echo "📦 Running unit tests..."
    xcodebuild -scheme "$SCHEME" \
               -destination "$DESTINATION" \
               -quiet \
               -only-testing:PrintMyRideTests/Unit \
               test || true
}

function run_ui_tests() {
    echo "🖥️ Running UI tests..."
    xcodebuild -scheme "$SCHEME" \
               -destination "$DESTINATION" \
               -quiet \
               -only-testing:PMRUITests \
               test || true
}

function run_snapshot_tests() {
    echo "📸 Running snapshot tests..."
    xcodebuild -scheme "$SCHEME" \
               -destination "$DESTINATION" \
               -quiet \
               -only-testing:PrintMyRideTests/Snapshot \
               test || true
}

function run_link_tests() {
    echo "🔗 Running link checker tests..."
    xcodebuild -scheme "$SCHEME" \
               -destination "$DESTINATION" \
               -quiet \
               -only-testing:PrintMyRideTests/LinkTests \
               test || true
}

# Main execution
case "${1:-all}" in
    all)
        run_all_tests
        ;;
    unit)
        run_unit_tests
        ;;
    ui)
        run_ui_tests
        ;;
    snapshot)
        run_snapshot_tests
        ;;
    links)
        run_link_tests
        ;;
    *)
        echo "Usage: $0 [all|unit|ui|snapshot|links]"
        exit 1
        ;;
esac

echo "✅ Test run complete!"