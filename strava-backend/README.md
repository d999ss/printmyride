# PrintMyRide Strava Backend

This is a Cloudflare Workers backend that handles Strava OAuth token exchange, keeping the client secret secure and off-device.

## Setup

1. **Create Strava App**:
   - Go to https://www.strava.com/settings/api
   - Create a new application
   - Set Authorization Callback Domain to your domain
   - Note your Client ID and Client Secret

2. **Deploy to Cloudflare Workers**:
   ```bash
   npm install
   wrangler secret put STRAVA_CLIENT_ID
   wrangler secret put STRAVA_CLIENT_SECRET
   wrangler deploy
   ```

3. **Update iOS App**:
   - In `StravaLinker.swift`, replace `YOUR_CLIENT_ID` with your actual Strava Client ID
   - In `StravaAPI.swift`, replace the backend URL with your deployed Workers URL

4. **Configure URL Scheme**:
   - In Xcode, go to PrintMyRide target → Info → URL Types
   - Add URL Scheme: `pmr`
   - This handles the OAuth redirect: `pmr://auth/strava`

## Endpoints

- `POST /exchange` - Exchange authorization code for tokens
- `POST /refresh` - Refresh access token

## Security

- Client secret never leaves the server
- CORS enabled for iOS app requests
- No sensitive data logged or stored

## Rate Limits

Strava API limits:
- 600 requests per 15 minutes
- 30,000 requests per day

The backend respects these limits by only handling token exchange, not data fetching.