# PrintMyRide CI/CD Setup

Complete CI/CD pipeline with Fastlane + GitHub Actions for automated TestFlight uploads using App Store Connect API.

## 🔑 App Store Connect API Configuration

- **Key ID**: MF59B82MMF  
- **Issuer ID**: PASTE_ISSUER_ID (replace with actual)
- **Bundle ID**: com.bttr.printmyride
- **Xcode Scheme**: PrintMyRide

## 📋 Setup Steps

### 1. Install Dependencies

**For GitHub Actions**: Dependencies are handled automatically.

**For local development** (requires Ruby 3.2+):
```bash
# Install dependencies
bundle install

# If you have Ruby version issues, consider using rbenv or similar:
# rbenv install 3.2.0
# rbenv local 3.2.0
```

### 2. Configure Secrets in GitHub

Go to **Repository Settings → Secrets and Variables → Actions** and add:

- `ASC_ISSUER_ID` = Your actual issuer ID (replace PASTE_ISSUER_ID)
- `ASC_P8_BASE64` = Base64 encoded private key

To generate the base64 key:
```bash
# Place your PrintMyRide_ASC.p8 file in ios/keys/
base64 -i ios/keys/PrintMyRide_ASC.p8 | pbcopy
```

### 3. Update Team IDs (Optional)

Edit `ios/fastlane/Appfile` with your actual values:
- `apple_id`: Your Apple ID email
- `itc_team_id`: App Store Connect team ID (numeric)
- `team_id`: Developer Portal team ID (10 characters)

## 🚀 Usage

### Automated TestFlight Upload

Push a version tag to trigger automatic build and upload:
```bash
git tag v1.0.0
git push origin v1.0.0
```

### Manual Commands

```bash
# Build app for App Store
bundle exec fastlane ios build

# Upload to TestFlight
bundle exec fastlane ios beta

# Submit to App Store (manual review)
bundle exec fastlane ios release

# Download finance reports
bundle exec fastlane ios pull_finance_reports
```

## 📊 Workflow Triggers

- **Tag pushes** (`v*`): Automatic TestFlight upload
- **Manual dispatch**: Run workflow manually from GitHub Actions tab
- To trigger on main branch pushes instead, modify `.github/workflows/ios-ci.yml`

## 🔒 Security Notes

- **NEVER commit** `.p8` files to git
- Private key is stored as encrypted GitHub secret
- Key ID is public, but issuer ID and private key must remain secret
- Finance reports are generated in `/reports` directory (ignored by git)

## ✅ Acceptance Criteria Met

- ✅ Pushing tags like `v1.0.0` triggers automated TestFlight upload
- ✅ App Store Connect API authentication configured
- ✅ Build increment and release notes automation
- ✅ Optional finance report downloads
- ✅ Secure key management with GitHub secrets
- ✅ Complete CI/CD pipeline ready for production use