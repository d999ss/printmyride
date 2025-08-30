# Strava OAuth Setup Checklist

## ✅ Debugging the Alert

The alert is likely `PMRError.notConnected` from missing configuration. Here's how to diagnose:

### 1. Check Console Logs
With the new debug logs, you'll see:
```
[Strava] clientId: 173748 exchange: https://your-worker.workers.dev/api/strava/exchange refresh: https://your-worker.workers.dev/api/strava/refresh
```

If you see `clientId: ` (empty) or `placeholder.invalid`, configuration failed.

### 2. Required Info.plist Keys
Add these to your app target's Info.plist:

```xml
<key>STRAVA_CLIENT_ID</key>
<string>173748</string>

<key>STRAVA_BACKEND_EXCHANGE</key>
<string>https://YOUR_WORKER.workers.dev/api/strava/exchange</string>

<key>STRAVA_BACKEND_REFRESH</key>
<string>https://YOUR_WORKER.workers.dev/api/strava/refresh</string>
```

### 3. URL Scheme Setup
In Xcode target settings:
- Info tab → URL Types
- Add: Identifier: `pmr`, URL Schemes: `pmr`

### 4. Configuration Loading
Verify `PrintMyRideApp.init()` calls:
```swift
if let cfg = StravaConfig.load() {
    StravaService.shared.configure(clientId: cfg.clientId,
                                   exchange: cfg.exchangeURL,
                                   refresh: cfg.refreshURL)
}
```

### 5. Worker Backend
Deploy the Cloudflare Worker with:
- `STRAVA_CLIENT_ID` = 173748
- `STRAVA_CLIENT_SECRET` = your secret from Strava

## 🚨 Common Issues

1. **notConnected** = Missing `STRAVA_CLIENT_ID` in Info.plist
2. **badCallback** = Missing `pmr` URL scheme or redirect mismatch
3. **http** = Worker returning non-200 (check backend logs)

## 🔍 Debug Steps

1. Clean build (Shift+Cmd+K)
2. Run on device (not simulator for OAuth)
3. Check console for debug logs
4. Try "Connect to Strava" button
5. Note specific error message

The new error handling will show exactly which step failed!