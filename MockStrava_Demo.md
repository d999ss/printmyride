# Mock Strava Mode - Usage Guide

## Overview
Mock Strava mode provides instant connection and demo rides for development, testing, and TestFlight builds without requiring real Strava OAuth or network calls.

## How to Enable

### Via Settings UI:
1. Open app → Settings (gear icon)
2. Go to "Connected Services" section
3. Toggle "Demo Mode (Mock Strava)" ON
4. Strava immediately shows as "Connected"

### Programmatically:
```swift
// Enable mock mode
UserDefaults.standard.set(true, forKey: "pmr.mockStrava")

// Access mock service
@EnvironmentObject var services: ServiceHub
let rides = try await services.strava.listRecentRides(limit: 10)
```

## Demo Rides Available

### 1. Park City Loop
- **Distance**: 32.5 km (20.2 miles)
- **Duration**: 1h 13m (4,380 seconds)  
- **Date**: Aug 15, 2025 2:00 PM UTC
- **GPX**: `Demo_ParkCity.gpx` (Park City, Utah)
- **Elevation**: 2103m - 2210m

### 2. Boulder Canyon Spin  
- **Distance**: 18.5 km (11.5 miles)
- **Duration**: 45m (2,700 seconds)
- **Date**: Jul 8, 2025 12:00 PM UTC  
- **GPX**: `Demo_Boulder.gpx` (Boulder, Colorado)
- **Elevation**: 1655m - 1715m

## Architecture

```
ServiceHub (@Published)
├── mockStrava: Bool → triggers service swap
├── strava: StravaAPI → StravaMock | StravaReal

StravaMock (when ON)
├── isConnected() → true
├── connect() → instant success
├── disconnect() → sets connected = false
├── listRecentRides() → returns demo rides

StravaReal (when OFF)  
├── isConnected() → checks Keychain tokens
├── connect() → throws (OAuth via StravaOAuth)
├── disconnect() → clears Keychain
├── listRecentRides() → real Strava API calls
```

## Use Cases

### ✅ Development
- Test UI without real Strava account
- Reliable demo data for screenshots
- No network dependencies

### ✅ TestFlight
- Demo app functionality to testers
- Works even if Strava API is down
- No OAuth setup required

### ✅ UI Tests
- Deterministic connection state
- Predictable ride data
- Fast test execution

## Integration Points

### Settings View:
```swift
@EnvironmentObject var services: ServiceHub

// Connection status
if services.mockStrava || oauth.isConnected {
    // Show as connected
}

// Toggle
Toggle("Demo Mode (Mock Strava)", isOn: $services.mockStrava)
```

### Gallery/Import Views:
```swift
@EnvironmentObject var services: ServiceHub

// Get rides
let rides = try await services.strava.listRecentRides(limit: 20)

// Check connection  
if services.strava.isConnected() {
    // Show rides or import UI
}
```

## Testing Mock Mode

1. **Enable**: Toggle "Demo Mode" in Settings
2. **Verify**: Strava shows "Connected" immediately  
3. **Test API**: Call `listRecentRides()` → returns 2 demo rides
4. **Disable**: Toggle OFF → reverts to real OAuth flow
5. **Persist**: Setting survives app restarts via `@AppStorage`

The mock mode provides a seamless fallback that makes the app always feel "alive" even without real Strava integration!