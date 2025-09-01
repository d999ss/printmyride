# PMR Test Harness

## Setup Requirements

### 1. Add Swift Package Manager Dependencies

Add the following SPM package to your Xcode project:
- **swift-snapshot-testing**: `https://github.com/pointfreeco/swift-snapshot-testing`
  - In Xcode: File → Add Package Dependencies
  - Enter the URL above
  - Link to test targets: PrintMyRideTests

### 2. Test Structure

```
Tests/
├── Support/          # Test helpers and utilities
├── Unit/            # Unit tests for models and stores
├── Snapshot/        # Visual regression tests
├── LinkTests/       # Dead link checker
└── README.md        # This file

PMRUITests/          # UI smoke tests
Fixtures/            # Test data and manifests
```

### 3. Running Tests

#### Via Makefile:
```bash
make test        # Run all tests
make unit        # Unit tests only
make ui          # UI tests only
make snapshot    # Snapshot tests only
make links       # Link checker only
```

#### Via Fastlane:
```bash
bundle exec fastlane ci
```

#### Via Xcode:
- Cmd+U to run all tests
- Select specific test schemes in the Test navigator

### 4. Test Mode

The app supports a special `--PMRTestMode` launch argument that:
- Clears local poster data for deterministic first-run testing
- Removes seeding flags to ensure clean slate
- Sets a UserDefaults flag for test mode detection

### 5. Updating Snapshots

To update snapshot golden files:
1. Open `Tests/Snapshot/GallerySnapshotTests.swift`
2. Set `isRecording = true` in `setUp()`
3. Run the snapshot tests
4. Review the generated snapshots in `__Snapshots__/`
5. Set `isRecording = false` before committing

### 6. Adding New Links

To add new external URLs for link checking:
1. Edit `Fixtures/Links.json`
2. Add the URL to the `links` array
3. Run `make links` to verify

### 7. Mocking Guidelines

- StoreKit: Use `SKTestSession` for subscription testing
- Strava: Mock `StravaService` with test tokens
- Network: Use `URLProtocol` stubs for deterministic responses