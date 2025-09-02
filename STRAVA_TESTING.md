# Strava Integration Testing for PrintMyRide

Complete testing framework for Strava API integration without touching real user accounts.

## Quick Start

### 1. Get Strava API Credentials

1. Create app at [Strava Settings](https://www.strava.com/settings/api)
2. Set **Authorization Callback Domain** to `developers.strava.com`
3. Use [Strava Playground](https://developers.strava.com/playground/) to get access token
4. Required scopes: `read,activity:read_all` (add `activity:write` for test data creation)

### 2. Environment Setup

```bash
export STRAVA_CLIENT_ID="your_client_id"
export STRAVA_CLIENT_SECRET="your_client_secret"  
export STRAVA_ACCESS_TOKEN="your_access_token"
```

### 3. Run Test Scripts

```bash
# Setup test environment with sample activities
./scripts/strava_test_setup.sh

# Demo API endpoints with curl commands
./scripts/strava_api_demo.sh

# Run automated integration tests
xcodebuild -project PrintMyRide.xcodeproj -scheme PrintMyRide test -only-testing:PrintMyRideTests/StravaIntegrationTests
```

## Testing Framework Components

### Script: `strava_test_setup.sh`
- ✅ Creates safe test activities (marked as "PMR Test")
- ✅ Tests authentication and API endpoints
- ✅ Generates cleanup commands for test data
- ✅ Creates configuration file for app integration

### Script: `strava_api_demo.sh`  
- ✅ Demonstrates all required API calls with curl
- ✅ Tests polyline decoding for poster generation
- ✅ Shows rate limiting and error handling
- ✅ Copy-paste commands for manual testing

### Test Suite: `StravaIntegrationTests.swift`
- ✅ End-to-end authentication testing
- ✅ Activity import and polyline decoding
- ✅ High-resolution streams for poster quality
- ✅ Rate limiting and error handling
- ✅ Complete Strava → PrintMyRide poster flow

## Core API Endpoints for PrintMyRide

### Authentication
```bash
# OAuth token exchange (PKCE)
curl -X POST https://www.strava.com/api/v3/oauth/token \
  -d client_id=$CLIENT_ID \
  -d grant_type=authorization_code \
  -d code=$CODE \
  -d code_verifier=$VERIFIER
```

### Activity Import
```bash
# List recent activities with route data
curl -H "Authorization: Bearer $TOKEN" \
  "https://www.strava.com/api/v3/athlete/activities?per_page=10"

# Get high-resolution route coordinates  
curl -H "Authorization: Bearer $TOKEN" \
  "https://www.strava.com/api/v3/activities/$ID/streams?keys=latlng&key_by_type=true"
```

### Polyline Decoding
- Use `PolylineDecoder.decode()` to convert `summary_polyline` to `[CLLocationCoordinate2D]`
- Feed coordinates directly to `LegacyRendererBridge.renderImage()` for poster generation

## Rate Limits & Best Practices

- **Overall**: 200 requests per 15 minutes
- **Non-upload**: 100 requests per 15 minutes  
- **Daily**: 2000 requests per day
- Always handle `429` responses with `Retry-After` header
- Use streams endpoint for high-quality poster rendering
- Prefer `summary_polyline` for quick previews

## Testing Data Management

### Safe Test Activities
All test scripts create activities marked with:
- Name prefix: "PMR Test:"  
- Description: "Test activity for PrintMyRide poster generation - safe to delete"

### Cleanup Commands
```bash
# Delete test activity
curl -X DELETE -H "Authorization: Bearer $TOKEN" \
  "https://www.strava.com/api/v3/activities/$ACTIVITY_ID"

# Or run automated cleanup
./scripts/strava_test_setup.sh  # Shows cleanup commands at end
```

## Integration with PrintMyRide

### Account System Integration
```swift
// Link Strava to user account
AccountStore.shared.setStravaLinked(true)

// Check Strava status
let isLinked = AccountStore.shared.account.stravaLinked
```

### Poster Generation Flow
1. **Import**: `fetchRecentActivities()` → get activities with `summary_polyline`
2. **Decode**: `PolylineDecoder.decode(polyline)` → `[CLLocationCoordinate2D]`
3. **Render**: `LegacyRendererBridge.renderImage(coords: coordinates)` → `UIImage`
4. **Save**: Use existing `PosterStore` to persist generated posters

### Error Handling
- `StravaError.rateLimitExceeded(retryAfter:)` → Wait and retry
- `StravaError.streamsNotAvailable` → Fall back to summary polyline
- `StravaError.httpError(401)` → Re-authenticate user

## Production Considerations

### OAuth Implementation
- Use PKCE flow for security (no client secret in app)
- Store refresh tokens securely in Keychain
- Handle token expiry gracefully

### Data Privacy  
- Only request minimum required scopes
- Allow users to disconnect/delete data
- Respect activity privacy settings

### Performance
- Cache decoded polylines to avoid repeated processing
- Use background queues for API calls
- Batch poster generation requests

## Testing Checklist

- [ ] Authentication flow works end-to-end
- [ ] Activity import handles various data formats
- [ ] Polyline decoding produces valid coordinates
- [ ] Poster generation works with Strava coordinates  
- [ ] Rate limiting is handled gracefully
- [ ] Error states have appropriate UI feedback
- [ ] Test data can be created and cleaned up safely
- [ ] Integration tests pass in CI environment

## Troubleshooting

**"Invalid credentials"**: Check access token in Playground first
**"Rate limited"**: Wait for next 15-minute window (0, 15, 30, 45 min)
**"Streams not available"**: Use summary_polyline as fallback
**"Empty coordinates"**: Activity may be manual entry without GPS data

---

This testing framework ensures PrintMyRide's Strava integration is bulletproof before touching any real user data! 🚴‍♂️