# Strava OAuth Setup Instructions

## 1. Add URL Scheme to Target

### Via Target Settings (Required)
1. Open Xcode project
2. Select PrintMyRide target
3. Go to Info tab
4. Expand "URL Types" section
5. Add new URL Type:
   - **URL Schemes**: `pmr`
   - **Identifier**: `com.printmyride.oauth`
   - **Role**: Editor

## 2. Configure Strava App Credentials

Update `Auth/StravaOAuth.swift` with your actual Strava app credentials:

```swift
private let clientID = "YOUR_ACTUAL_STRAVA_CLIENT_ID"
private let clientSecret = "YOUR_ACTUAL_STRAVA_SECRET"
```

## 3. Deploy OAuth Redirect Handler

Deploy the redirect handler to `https://pmr-auth.vercel.app/strava` that:
1. Receives OAuth callback from Strava
2. Redirects to `pmr://auth/strava?code=AUTHORIZATION_CODE`

Example implementation:
```javascript
// pages/api/strava.js (Next.js/Vercel)
export default function handler(req, res) {
  const { code, state } = req.query;
  if (code) {
    res.redirect(`pmr://auth/strava?code=${code}`);
  } else {
    res.status(400).json({ error: 'Missing authorization code' });
  }
}
```

## 4. Test OAuth Flow

1. Build and run app on device/simulator
2. Go to Settings → Connected Services
3. Tap "Connect" next to Strava
4. Complete OAuth flow in browser
5. Verify app receives redirect and saves tokens

## 5. Troubleshooting

- Ensure URL scheme `pmr://` is registered in Info.plist
- Check that redirect URL in Strava app settings matches `https://pmr-auth.vercel.app/strava`
- Verify client ID/secret are correct
- Test on physical device for full OAuth flow