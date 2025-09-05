# Multi-User Strava Integration Setup Guide

This guide walks you through setting up the complete multi-user Strava integration for PrintMyRide, compliant with Strava's November 2024 API requirements.

## 🎯 Overview

The new system provides:
- **Passwordless email authentication** for your app users
- **Individual Strava connections** per user with OAuth2
- **Privacy-compliant data access** (users see only their own activities)
- **GPX export functionality** with multi-select and ZIP download
- **Automatic token management** with refresh handling
- **Clean disconnection** with proper Strava deauthorization

## 📋 Prerequisites

1. **Strava Developer Account**
   - Register at [developers.strava.com](https://developers.strava.com)
   - Create a new application
   - Note your Client ID and Client Secret

2. **Database** (PostgreSQL recommended)
   - Local PostgreSQL installation or cloud service (Heroku, AWS RDS, etc.)

3. **Email Service** (for magic links)
   - Gmail, SendGrid, Ethereal (dev), or any SMTP service

4. **Development Environment**
   - Node.js 18+ with npm/yarn
   - Xcode 15+ for iOS app
   - PostgreSQL client tools

## 🗃️ Database Setup

1. **Install PostgreSQL** (if not already installed):
```bash
# macOS
brew install postgresql
brew services start postgresql

# Ubuntu/Debian
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

2. **Create database**:
```bash
createdb printmyride
```

3. **Run migrations**:
```bash
cd server
npm install
npm run migrate
```

The schema creates these tables:
- `users` - Your app users
- `login_tokens` - Magic link tokens
- `user_identities` - Maps users to Strava athletes
- `strava_tokens` - OAuth tokens per athlete
- `strava_activities` - Cached activity data
- `download_links` - Optional signed URLs for exports

## 🔧 Server Configuration

1. **Copy environment file**:
```bash
cd server
cp .env.example .env
```

2. **Configure environment variables**:
```env
# Database
DATABASE_URL=postgresql://username:password@localhost:5432/printmyride

# JWT Secret (generate with: openssl rand -base64 32)
JWT_SECRET=your-super-secret-jwt-key

# Strava OAuth
STRAVA_CLIENT_ID=12345
STRAVA_CLIENT_SECRET=your-strava-client-secret

# URLs
APP_BASE_URL=http://localhost:3000      # Your app's URL
SERVER_BASE_URL=http://localhost:3001   # Your API server URL

# Email (SMTP)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
FROM_EMAIL=noreply@printmyride.app

# Server
PORT=3001
NODE_ENV=development
```

3. **Start the server**:
```bash
npm run dev    # Development with auto-reload
npm run build && npm start  # Production
```

The server runs on `http://localhost:3001` by default.

## 📱 iOS App Configuration

1. **Update base URLs** in the iOS services:
   - Edit `AuthService.swift` - Update `baseURL` for your server
   - Edit `MultiUserStravaService.swift` - Update `baseURL` for your server

2. **Configure URL schemes** in `Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>PrintMyRide</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>pmr</string>
            <string>printmyride</string>
        </array>
    </dict>
</array>
```

3. **Update Strava redirect URI** in your Strava app settings:
   - Go to [developers.strava.com](https://developers.strava.com)
   - Edit your application
   - Set Authorization Callback Domain to: `localhost` (for dev) or `printmyride.app` (for prod)

## 🔐 Strava App Configuration

1. **Login to Strava Developers**:
   - Go to [developers.strava.com](https://developers.strava.com)
   - Click "Create & Manage Your App"

2. **Create or edit your application**:
   - **Application Name**: PrintMyRide
   - **Category**: Cycling
   - **Website**: https://printmyride.app
   - **Authorization Callback Domain**: 
     - Development: `localhost`
     - Production: `printmyride.app`

3. **Configure OAuth settings**:
   - **Client ID**: Copy to your `.env` file
   - **Client Secret**: Copy to your `.env` file (keep secret!)
   - **Redirect URIs**: Your server handles these automatically

4. **Request appropriate scopes**:
   The integration requests: `read,activity:read,activity:read_all`

## 🚀 Running the Complete System

1. **Start the backend**:
```bash
cd server
npm run dev
```

2. **Build and run iOS app**:
   - Open `PrintMyRide.xcodeproj` in Xcode
   - Update the server URLs in the service files
   - Build and run on simulator or device

3. **Test the flow**:
   - Launch the app → see login screen
   - Enter email → receive magic link email
   - Click link → redirected to app as authenticated user
   - Connect to Strava → OAuth flow in web view
   - View activities → see your Strava rides
   - Select activities → export as GPX ZIP

## 🔄 Flow Diagrams

### Authentication Flow
```
User → Email Input → Magic Link Email → Click Link → Authenticated
```

### Strava Connection Flow
```
Authenticated User → Connect Strava → OAuth Web View → Token Exchange → Connected
```

### Activity Access Flow
```
Connected User → Request Activities → Server checks auth → Fetch from Strava → Cache & Return
```

### Export Flow
```
User selects activities → Server validates ownership → Generate GPX → Create ZIP → Download
```

## 🛠️ API Endpoints

The server provides these endpoints:

**Authentication**:
- `POST /auth/email/start` - Send magic link
- `GET /auth/email/callback` - Validate token, issue session
- `GET /auth/status` - Check current auth status
- `POST /auth/logout` - Clear session

**Strava Integration**:
- `GET /auth/strava` - Start OAuth flow
- `GET /auth/strava/callback` - Handle OAuth callback
- `POST /api/strava/deauthorize` - Disconnect Strava

**Data Access**:
- `GET /api/activities` - Get user's activities (paginated)
- `GET /api/exports/gpx?ids=1,2,3` - Export selected activities as ZIP

**Health**:
- `GET /health` - Server health check

## 🔒 Privacy & Compliance

This implementation complies with Strava's November 2024 requirements:

✅ **User data isolation**: Each user sees only their own activities  
✅ **No AI training**: Activity data is not used for AI/ML training  
✅ **Proper authentication**: OAuth2 with proper scopes  
✅ **Token management**: Automatic refresh, secure storage  
✅ **Clean disconnection**: Proper deauthorization with Strava  

## 🐛 Troubleshooting

### Common Issues

1. **"Authentication required" errors**:
   - Check that JWT_SECRET is set and consistent
   - Verify cookies are being sent with requests
   - Ensure CORS is configured for your app domain

2. **Strava OAuth failures**:
   - Verify CLIENT_ID and CLIENT_SECRET in `.env`
   - Check redirect URI configuration in Strava app settings
   - Ensure callback domain matches your server URL

3. **Database connection errors**:
   - Verify DATABASE_URL is correct
   - Check PostgreSQL is running
   - Run migrations with `npm run migrate`

4. **Email not sending**:
   - Check SMTP credentials in `.env`
   - For Gmail, use App Passwords instead of regular password
   - Test with Ethereal Email for development

5. **Token refresh failures**:
   - Check network connectivity to Strava API
   - Verify tokens haven't been manually revoked
   - Look for rate limiting (429) responses

### Development Tips

- Use Ethereal Email for testing magic links in development
- Set `NODE_ENV=development` for detailed error messages
- Check server logs for API rate limiting warnings
- Use PostgreSQL GUI tools to inspect data during development

## 🚢 Production Deployment

1. **Environment setup**:
   - Set `NODE_ENV=production`
   - Use production database URL
   - Configure real SMTP service
   - Set production app/server URLs

2. **Security considerations**:
   - Use HTTPS for all URLs in production
   - Set secure cookie flags
   - Configure proper CORS origins
   - Use strong JWT secrets

3. **Scaling considerations**:
   - Consider Redis for session storage at scale
   - Implement rate limiting middleware
   - Add monitoring and logging
   - Use connection pooling for database

## ✅ Testing Checklist

- [ ] User can sign up with email magic link
- [ ] User can connect to Strava via OAuth
- [ ] User sees only their own activities
- [ ] Activity list loads and paginates correctly
- [ ] User can select multiple activities
- [ ] GPX export creates downloadable ZIP
- [ ] User can disconnect from Strava
- [ ] Tokens refresh automatically when expired
- [ ] All endpoints require proper authentication
- [ ] Privacy: no user can see another's data

## 📚 Additional Resources

- [Strava API Documentation](https://developers.strava.com/docs/)
- [OAuth2 RFC](https://tools.ietf.org/html/rfc6749)
- [JWT Best Practices](https://auth0.com/blog/a-look-at-the-latest-draft-for-jwt-bcp/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

🎉 **Congratulations!** You now have a complete multi-user Strava integration that complies with the latest API requirements and provides a great user experience.