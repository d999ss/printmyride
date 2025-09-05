#!/bin/bash

# Emergency Rollback Script for PrintMyRide Refactoring
# Use this if refactoring causes issues

set -e

echo "🚨 EMERGENCY ROLLBACK INITIATED"
echo "================================"

# Check for rollback tag argument
if [ -z "$1" ]; then
    echo "Available rollback points:"
    git tag | grep pre-refactor
    echo ""
    echo "Usage: ./emergency_rollback.sh <tag-name>"
    echo "Example: ./emergency_rollback.sh pre-refactor-phase-1"
    exit 1
fi

ROLLBACK_TAG=$1

echo "⚠️  WARNING: This will rollback to: $ROLLBACK_TAG"
echo "Current branch will be backed up to: rollback-backup-$(date +%Y%m%d-%H%M%S)"
read -p "Continue? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Rollback cancelled"
    exit 0
fi

# Create backup branch
BACKUP_BRANCH="rollback-backup-$(date +%Y%m%d-%H%M%S)"
git branch $BACKUP_BRANCH
echo "✅ Current state backed up to: $BACKUP_BRANCH"

# Stash any uncommitted changes
if [[ -n $(git status -s) ]]; then
    git stash push -m "Emergency rollback stash $(date)"
    echo "✅ Uncommitted changes stashed"
fi

# Rollback to tag
git checkout $ROLLBACK_TAG
echo "✅ Rolled back to: $ROLLBACK_TAG"

# Rebuild
echo "🔨 Rebuilding app..."
xcodebuild -scheme PrintMyRide -destination "platform=iOS Simulator,name=iPhone 16 Pro" clean build

# Quick feature flag override
echo "🏳️ Disabling all feature flags..."
cat > /tmp/rollback_flags.swift << 'EOF'
// EMERGENCY OVERRIDE - Remove this file after issue is resolved
extension FeatureFlags {
    static let emergencyOverride = true
}
EOF

# If FeatureFlags.swift exists, set all to false
if [ -f "PrintMyRide/Core/FeatureFlags.swift" ]; then
    sed -i '' 's/static let use[A-Za-z]* = true/static let use\0 = false/g' PrintMyRide/Core/FeatureFlags.swift
    sed -i '' 's/static let require[A-Za-z]* = true/static let require\0 = false/g' PrintMyRide/Core/FeatureFlags.swift
    echo "✅ Feature flags disabled"
fi

echo ""
echo "========================================="
echo "🚨 ROLLBACK COMPLETE"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Test the app to verify it's working"
echo "2. Check the backup branch: $BACKUP_BRANCH"
echo "3. File an issue with details about what went wrong"
echo "4. To return to previous work: git checkout $BACKUP_BRANCH"
echo ""
echo "To see what changed:"
echo "git diff $ROLLBACK_TAG $BACKUP_BRANCH"