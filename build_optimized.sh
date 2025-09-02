#!/bin/bash
# Enhanced build script with optimizations and error handling
set -euo pipefail

SCHEME="PrintMyRide"
DESTINATION="platform=iOS Simulator,name=iPhone 16 Pro"
START_TIME=$(date +%s)

echo "🚀 Building PrintMyRide with optimizations..."

# Clean build with performance optimizations
xcodebuild \
    -project PrintMyRide.xcodeproj \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -configuration Debug \
    -quiet \
    clean build \
    ENABLE_TESTABILITY=YES \
    SWIFT_COMPILATION_MODE=singlefile \
    SWIFT_OPTIMIZATION_LEVEL="-Onone" \
    BUILD_INDEPENDENT_TARGETS_IN_PARALLEL=YES \
    ASSETCATALOG_COMPILER_OPTIMIZATION=time

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo "✅ Build completed successfully in ${DURATION} seconds"
echo "$(date): Build completed in ${DURATION}s" >> build_times.log

# Show build timing summary
echo "📊 Build Performance Summary:"
xcodebuild -project PrintMyRide.xcodeproj -scheme "$SCHEME" -showBuildTimingSummary build | tail -10