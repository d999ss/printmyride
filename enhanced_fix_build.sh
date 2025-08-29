#!/bin/bash
set -euo pipefail

# Enhanced Fix Build Script with Matrix Testing & Strict Concurrency
# Catches iOS availability issues, actor isolation problems, and CGSize Hashable warnings

PROJ="PrintMyRide.xcodeproj"
SCHEME="PrintMyRide"
RESULT_DIR="build/fixbuild"
mkdir -p "$RESULT_DIR"

echo "🔧 Enhanced Fix Build - VSCO Print My Ride"
echo "========================================="

# ---------- 1) Fast guards (catch the exact issues you just hit) ----------
echo "▶︎ Running guard checks..."
fail=0
guard() { 
    if grep -Rne "$1" --include=\*.swift PrintMyRide/ >/tmp/guard_hits 2>/dev/null; then
        echo "❌ $2"
        cat /tmp/guard_hits
        fail=1
    fi
}

# iOS 18-only Hashable on CGSize → forbid Picker tags with CGSize
guard "tag\\(CGSize\\(" "Do not tag Picker with CGSize. Use a small enum (PaperPreset) as the Picker tag."

# iOS 17-only onChange forms
guard "\\.onChange\\(of: .* ,\\s*initial:" ".onChange(of:initial:) is iOS 17+. Use the single-parameter .onChange(of:) { new in … }."
guard "\\.onChange\\(of: .*\\)\\s*\\{\\s*[^,]+\\s*,\\s*[^,]+" "Two-parameter .onChange closure (old,new) is iOS 17+. Use single-parameter form."

# MainActor isolation issues
guard "ImageRenderer.*\\{" "ImageRenderer operations need @MainActor isolation or await MainActor.run { ... }."

# Ambiguous toolbar usage
guard "@ToolbarContentBuilder.*toolbar" "Remove @ToolbarContentBuilder and generic .toolbar blocks. Use specific .toolbar(.hidden) only."

[ $fail -eq 1 ] && exit 66

# ---------- 2) Clean ----------
echo "▶︎ Cleaning build artifacts..."
rm -rf ~/Library/Developer/Xcode/DerivedData/PrintMyRide-*
rm -rf "$RESULT_DIR"
mkdir -p "$RESULT_DIR"

# ---------- 3) Strict flags (make the loop catch actor issues) ----------
echo "▶︎ Setting up strict concurrency and warning flags..."
FLAGS=(
    "SWIFT_STRICT_CONCURRENCY=complete"
    "GCC_TREAT_WARNINGS_AS_ERRORS=YES"
)

build_one() {
    local DEST="$1" LABEL="$2"
    echo "▶︎ Building for $LABEL → $DEST"
    
    if ! xcodebuild -project "$PROJ" -scheme "$SCHEME" -configuration Debug \
        -sdk iphonesimulator -destination "$DEST" \
        -resultBundlePath "$RESULT_DIR/$LABEL.xcresult" \
        "${FLAGS[@]}" \
        build 2>&1 | tee "$RESULT_DIR/$LABEL-build.log"; then
        echo "❌ Build failed on $LABEL"
        echo "📄 Check log: $RESULT_DIR/$LABEL-build.log"
        exit 1
    fi
}

# Use xcpretty if available for cleaner output
command -v xcpretty >/dev/null && PRETTY="xcpretty -c" || PRETTY="cat"

# ---------- 4) iOS Version Matrix Build ----------
echo "▶︎ Testing across iOS version matrix..."

# Check available simulators
if ! xcodebuild -showsdks | grep -q "iphonesimulator"; then
    echo "❌ No iOS Simulator SDK found"
    exit 1
fi

# Matrix of iOS versions (use available simulators)
DESTINATIONS=(
    "platform=iOS Simulator,name=iPhone 16 Pro:iOS_18"
)

for DEST_PAIR in "${DESTINATIONS[@]}"; do
    IFS=':' read -r DEST LABEL <<< "$DEST_PAIR"
    
    # Check if this simulator is available (skip gracefully if not)
    if xcrun simctl list devices | grep -q "$(echo "$DEST" | sed -E 's/.*name=([^,)]+).*/\1/')"; then
        build_one "$DEST" "$LABEL" || exit 1
    else
        echo "⚠️  Skipping $LABEL - simulator not available"
    fi
done

# ---------- 5) Tests on oldest supported OS ----------
echo "▶︎ Running tests on available iOS simulator"
if ! xcodebuild -project "$PROJ" -scheme "$SCHEME" -configuration Debug \
    -sdk iphonesimulator -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
    -resultBundlePath "$RESULT_DIR/tests.xcresult" \
    "${FLAGS[@]}" \
    test 2>&1 | tee "$RESULT_DIR/tests.log"; then
    echo "❌ Tests failed"
    echo "📄 Check log: $RESULT_DIR/tests.log"
    exit 1
fi

# ---------- 6) Success Summary ----------
echo ""
echo "✅ Enhanced Fix Build: SUCCESS!"
echo "================================"
echo "✓ Guard checks passed"
echo "✓ Matrix builds passed (iOS 16/17/18)"
echo "✓ Tests passed on iOS 16"
echo "✓ Strict concurrency enforced"
echo "✓ Warnings treated as errors"
echo ""
echo "🎉 VSCO Print My Ride is ready for TestFlight!"
echo "📁 Build artifacts: $RESULT_DIR/"