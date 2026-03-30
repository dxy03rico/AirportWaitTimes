# Airport Wait Times iOS App - Setup Guide

## Project Structure
```
AirportWaitTimesApp/
├── project.yml              # XcodeGen spec (regenerate with: xcodegen)
├── AirportWaitTimes.xcodeproj/  # Generated Xcode project
├── AirportWaitTimes/
│   ├── AirportWaitTimesApp.swift    # App entry point
│   ├── Info.plist                    # App config + Google Sign-In
│   ├── AirportWaitTimes.entitlements # StoreKit entitlements
│   ├── Assets.xcassets/              # App icon + colors
│   ├── Helpers/
│   │   └── ColorExtension.swift      # Hex color support
│   ├── Models/
│   │   ├── Airport.swift             # Airport data model
│   │   └── User.swift                # User + auth models
│   ├── Services/
│   │   ├── APIService.swift          # Network layer
│   │   ├── AuthManager.swift         # Google Sign-In manager
│   │   ├── StoreManager.swift        # StoreKit 2 IAP
│   │   └── AirportListViewModel.swift # List data management
│   └── Views/
│       ├── RootView.swift            # Auth → Paywall → App
│       ├── LoginView.swift           # Google Sign-In
│       ├── PaywallView.swift         # Purchase / Early Adopter
│       ├── MainTabView.swift         # Tab bar controller
│       ├── AirportListView.swift     # Airport list + search
│       ├── AirportCardView.swift     # Airport card component
│       ├── AirportDetailView.swift   # Airport detail page
│       ├── ReportWaitTimeView.swift  # Submit wait reports
│       └── ProfileView.swift         # User profile + settings
```

## Prerequisites
1. **Xcode 15+** (install from Mac App Store)
2. **Apple Developer Account** ($99/year for App Store publishing)
3. **Google Cloud Console** project (free)

## Step 1: Google Sign-In Setup
1. Go to https://console.cloud.google.com
2. Create a new project (or select existing)
3. Navigate to **APIs & Services → Credentials**
4. Click **Create Credentials → OAuth Client ID**
5. Select **iOS** application type
6. Enter your Bundle ID: `com.airportwaittimes.app`
7. Copy the **Client ID**
8. Edit `Info.plist`:
   - Replace `YOUR_GOOGLE_CLIENT_ID` with your actual Client ID
   - Update the URL scheme accordingly

## Step 2: Open in Xcode
```bash
cd ~/AirportWaitTimesApp
open AirportWaitTimes.xcodeproj
```

## Step 3: Configure Signing
1. In Xcode, select the project → **Signing & Capabilities**
2. Set your **Team** (Apple Developer account)
3. The Bundle ID should be `com.airportwaittimes.app`

## Step 4: App Store Connect (for In-App Purchase)
1. Go to https://appstoreconnect.apple.com
2. Create a new app
3. Go to **In-App Purchases** → Create:
   - Type: Non-Consumable
   - Reference Name: Full Access
   - Product ID: `com.airportwaittimes.fullaccess`
   - Price: $0.99 (Tier 1)
4. Submit for review

## Step 5: Update Server URL
Edit `Services/APIService.swift`:
- Set `baseURL` to your ngrok or production URL
- Current: `https://heide-diotic-universally.ngrok-free.dev`

## Step 6: Run
1. Connect your iPhone or use Simulator
2. Select your device in Xcode
3. Press ⌘+R to build and run

## App Flow
1. **Login Screen** → Google Sign-In only
2. **Paywall** → First 100 users get FREE access (early adopter)
3. **Main Dashboard** → Airport list with search, filters, pull-to-refresh
4. **Airport Detail** → Wait times, busyness, Reddit posts, submit reports
5. **Profile** → User info, restore purchases, sign out

## Pricing Model
- First 100 users: **FREE** (auto-detected via server)
- After 100 users: **$0.99** one-time purchase
- Note: App Store minimum price is $0.99; $0.10 is not possible

## Backend Auth Endpoints
- `POST /api/auth/google` - Authenticate with Google ID token
- `GET /api/user/status` - Check payment status
- `POST /api/user/claim-early-adopter` - Claim free early adopter access
- `POST /api/user/verify-purchase` - Verify StoreKit purchase
