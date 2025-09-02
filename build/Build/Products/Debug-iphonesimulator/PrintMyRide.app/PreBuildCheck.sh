#!/bin/bash
set -e

# 1) Fail on duplicate PosterDesign.swift anywhere
COUNT=$(git ls-files | grep -E '/PosterDesign\.swift$' | wc -l | tr -d ' ')
if [ "$COUNT" -ne 1 ]; then
  echo "Error: Found $COUNT PosterDesign.swift files. Keep one in PrintMyRide/Models."
  git ls-files | grep -E '/PosterDesign\.swift$' || true
  exit 1
fi

# 2) Enforce canonical path casing
BAD=$(git ls-files | grep -E '^printmyride/' || true)
if [ -n "$BAD" ]; then
  echo "Error: Lowercase 'printmyride/' path detected. Use 'PrintMyRide/'."
  echo "$BAD"
  exit 1
fi

# Canonical file protection (fail build if locally modified)
for F in PrintMyRide/Models/PosterDesign.swift PrintMyRide/Features/Render/GridOverlay.swift; do
  if ! git diff --quiet -- "$F"; then
    echo "❌ Canonical file changed: $F"
    echo "  These files are locked. Revert or update the spec and remove this guard intentionally."
    exit 1
  fi
done

echo "✅ Pre-build checks passed"

