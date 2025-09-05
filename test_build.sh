#!/bin/bash
set -e

echo "🔨 Testing iOS app compilation..."

cd /Users/donnysmith/CC/printmyride

# Clean build folder first
echo "🧹 Cleaning build folder..."
rm -rf build/
xcodebuild clean -project PrintMyRide.xcodeproj -scheme PrintMyRide

# Build for simulator
echo "📱 Building for iOS Simulator..."
xcodebuild -project PrintMyRide.xcodeproj -scheme PrintMyRide -destination "platform=iOS Simulator,name=iPhone 16 Pro" build -quiet

echo "✅ Build completed successfully!"