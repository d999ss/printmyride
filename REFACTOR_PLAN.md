# PrintMyRide Safe Refactoring Plan

## Phase 1: Setup (Week 1) ✅
- [x] Create FeatureFlags.swift for gradual rollout
- [x] Create test_current_behavior.sh to capture baseline
- [x] Document refactoring plan

## Phase 2: Identify Redundancies (Week 2)

### Poster Generation (Potential -2000 lines)
**Current:** 3 different implementations
- `PosterRenderer.swift` - Original implementation
- `PosterRenderService.swift` - Service version  
- `MapSnapshotService.swift` - Map-specific version
- `createSimpleTestPoster()` - Workaround code

**Target:** Single unified `PosterService`
```swift
if FeatureFlags.useSimplifiedPosterRenderer {
    return PosterService.shared.render(ride)
} else {
    // Keep current complex flow
}
```

### Authentication (Potential -1500 lines)
**Current:** Duplicate systems
- `AuthService.swift` - Main auth
- `StravaOAuth.swift` - Strava-specific
- `StravaAuthManager.swift` - Another layer
- Demo/Skip auth flows

**Target:** Single `AuthManager`

### Data Storage (Potential -1000 lines)
**Current:** Multiple caching layers
- `LibraryStore.swift`
- `PosterSnapshotStore.swift`
- `ImageCache.swift`
- Various UserDefaults usage

**Target:** Single `DataStore` with clear cache policy

### UI Components (Potential -2500 lines)

#### Poster Designs (Currently 10+)
Keep only:
- Classic
- Modern  
- Studio

Remove:
- Terracotta, Night, Glacier, Desert, etc.

#### Duplicate Views
- Multiple poster detail views
- Test/placeholder components
- Unused onboarding screens

### Sample/Mock Data (Potential -1000 lines)
- Remove hardcoded routes
- Remove sample generators
- Remove test data

## Phase 3: Gradual Rollout (Weeks 3-4)

### Week 3: Non-Critical Paths
1. Enable `useCorePosterDesigns` - Reduce design options
2. Enable `disableMockData` - Remove test data
3. Monitor for issues

### Week 4: Semi-Critical Paths  
1. Enable `useSimplifiedStorage` - Unified caching
2. Enable `hidePlaceholderViews` - Remove demo UI
3. Test extensively

## Phase 4: Critical Paths (Week 5)
1. Enable `useSimplifiedPosterRenderer` - Core feature
2. Enable `useUnifiedAuth` - Authentication
3. Keep old code for 2 weeks minimum

## Phase 5: Cleanup (Week 7)
Only after 2 weeks stable:
1. Remove old implementations
2. Delete feature flags
3. Final cleanup

## Rollback Strategy

### Instant Rollback
```swift
// In AppDelegate or main App file
FeatureFlags.useOriginalImplementation = true
```

### Git Rollback Points
```bash
# Tag before each phase
git tag pre-refactor-phase-1
git tag pre-refactor-phase-2
# etc.
```

### Monitoring Checklist
- [ ] Crash rate unchanged
- [ ] All screens load
- [ ] Poster generation works
- [ ] Auth flow works
- [ ] No performance regression

## Expected Results
- **Before:** ~17,000 lines
- **After:** ~10,000 lines  
- **Removed:** ~7,000 lines (40% reduction)
- **Risk:** Minimal with gradual rollout
- **Timeline:** 7 weeks total

## Commands

### Run baseline test
```bash
./test_current_behavior.sh
```

### Check specific flag impact
```bash
# See what code uses a flag
grep -r "useSimplifiedPosterRenderer" PrintMyRide/
```

### Emergency revert
```bash
git checkout pre-refactor-phase-X
```

## Success Metrics
- No increase in crash rate
- No user-reported issues
- Performance same or better
- Code coverage maintained
- All tests passing