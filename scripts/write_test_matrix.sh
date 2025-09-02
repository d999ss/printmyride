#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
OUT="$ROOT/TEST_MATRIX.md"

mkdir -p "$ROOT/scripts"

cat > "$OUT" <<'MD'
# PrintMyRide — Regression Testing Matrix

This file lists the core flows to test before each TestFlight or App Store submission.  
All steps must PASS with no crashes, broken navigation, or visual blockers.

---

## 1. Studio
- [ ] Tap **Alpine Climb** card → opens Poster Detail with poster visible
- [ ] Tap **Forest Switchbacks** card → opens Poster Detail with poster visible
- [ ] Hero banner renders correctly (no duplicate **Try Pro** or **Settings**)

## 2. Poster Detail
- [ ] Tap **Open in Apple Maps** → Simulator opens Maps, app resumes
- [ ] Tap **Save Map Snapshot** → Snapshot saved, thumbnail updates in Studio
- [ ] Tap **Export High-Res (PDF)** → File saved, no error
- [ ] Tap **Print Poster** → Demo checkout view appears
- [ ] Tap **Share Poster Image** → Share sheet appears and can dismiss
- [ ] Poster width matches 4-button bar below
- [ ] Poster shows route + stats (distance, climb, time, date) ON the poster

## 3. Tabs
- [ ] Switch **Studio ↔ Collections** → Navigation works, state preserved
- [ ] Switch **Studio ↔ Settings** → Navigation works, toggles available

## 4. Settings
- [ ] Toggle **Apple Maps background** → Poster re-renders with/without background
- [ ] Change **Units (mi/km)** → Stats update accordingly
- [ ] Change **Paper preset** → Poster aspect ratio updates
- [ ] Style presets (Classic, Mono, Glow, Cornsilk) re-render correctly

## 5. Pro / Subscription
- [ ] **Try Pro** button in toolbar → Opens paywall (only once, not duplicated)
- [ ] Export/share when not Pro → Shows Pro gating (no duplicate Try Pro badges)
- [ ] Restore purchases flow visible in Settings

## 6. Onboarding
- [ ] First launch shows onboarding
- [ ] "Skip for now" works → Goes to Studio
- [ ] Demo posters (Alpine Climb, Forest Switchbacks, others) always load

## 7. Strava (when enabled)
- [ ] Connect Strava → OAuth flow completes, activities import
- [ ] Disconnect Strava → Returns to Demo Mode
- [ ] Demo Mode toggle in Settings works

---

### Quick Run Command

To sanity check in CI or locally:

```bash
xcodebuild \
  -scheme PrintMyRide \
  -destination "platform=iOS Simulator,name=iPhone 16 Pro" \
  clean build test
```
MD

echo "✅ Wrote regression matrix to $OUT"