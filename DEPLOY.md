# 🚀 PrintMyRide Simple Deployment

## Quick Commands

### One-line deploy (commit + tag + TestFlight):
```bash
bundle exec fastlane ios deploy message:"Your commit message here"
```

### Just TestFlight upload:
```bash
bundle exec fastlane ios beta
```

### Just build:
```bash
bundle exec fastlane ios build
```

## What the deploy command does:
1. Commits all changes with your message
2. Increments build number automatically
3. Creates git tag (e.g., `v1.0-123`)
4. Pushes to git
5. Builds app for App Store
6. Uploads to TestFlight

## Setup (one time):
1. Add your ASC private key to `ios/keys/PrintMyRide_ASC.p8`
2. Set environment variable: `export ASC_ISSUER_ID=your_issuer_id`
3. Run: `bundle install`

That's it! 🎯