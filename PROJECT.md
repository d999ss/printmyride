# PROJECT.md – Print My Ride (PMR)

## 1. Overview
Name: Print My Ride (PMR)  
Platform: iOS, SwiftUI  
Core Concept: Transform Strava ride data into custom-designed posters that users can download in high resolution or purchase as physical prints.  
Status: In TestFlight. UX functional, subscription funnel being finalized, polish ongoing.  

## 2. Design Principles
- UX inspired by Strava — clean, athletic, data-driven  
- Visual identity: topography & GPS lines only (no cars)  
- Poster generation is the hero feature  
- Keep app fast, simple, focused  
- Default to native iOS patterns  

## 3. Architecture & Tech Stack
- Frontend: SwiftUI  
- Poster Rendering: custom SwiftUI view model  
- Data Source: Strava API (ride data via GPX import)  
- Persistence: none in V1 (fetch from Strava each time)  
- Subscriptions: StoreKit2  
- Analytics: Apple App Analytics + Crashlytics  
- Backend: none in V1 beyond Strava + print API  

## 4. Features
### Core (V1)
- Import ride from Strava  
- Generate low-res watermarked poster preview  
- Subscription paywall to unlock high-res export  
- High-res export (PDF/JPEG)  
- Physical print ordering via partner API (Gelato/Printful)  

### Future (V2+)
- Poster customization (colors, captions, sizes)  
- Ride collections  
- Social sharing  
- Offline ride storage  
- Push notifications  

## 5. Monetization
- Free: ride import + low-res watermarked preview only  
- Subscription (mandatory for real use): unlimited high-res exports, monthly + annual plans (annual discounted ~20–30%)  
- Upsell: print ordering via Gelato/Printful, available only to subscribed users  

## 6. Non-Negotiables
- Brand: always Print My Ride (PMR)  
- Visuals: no cars, only maps/GPS/topo  
- Poster rendering deterministic: same input → same output  
- V1 scope must remain focused: import → paywall → poster  

## 7. Current Status & Known Issues
- TestFlight live  
- PosterPreview binding bugs  
- Background cropping issue  
- Subscription funnel not yet live  
- Walkthrough screens, app icon, description in progress  

## 8. Developer Workflow
Setup:
  cd /Users/donnysmith/CC/printmyride
  open PrintMyRide.xcodeproj

Build/Run:
  xcodebuild -scheme PrintMyRide -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

Lint:
  swiftlint

## 9. Roadmap (Q3–Q4 2025)
1. Finalize subscription paywall flow (StoreKit2)  
2. Integrate print ordering (Gelato/Printful)  
3. Polish onboarding & walkthrough screens  
4. Push to App Store  
5. Add customization (V2)  

## 10. Claude Rules
- Always reference this doc before answering  
- Do not invent new features unless added here  
- Stay within V1 scope unless asked to roadmap future  
- Subscription-first monetization is non-negotiable