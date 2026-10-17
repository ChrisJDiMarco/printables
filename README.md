# Printables — for little learners

A native SwiftUI iOS app that turns any photo into a beautiful, child-friendly printable worksheet for kids age 4–6.

> Snap a photo → describe what to teach → OpenAI generates a one-page printable PDF (cover, intro, tracing, counting, coloring, drawing, vocabulary, fun fact, and grown-up tip).

---

## Quick start

```bash
# 1. Open the project
open Printables.xcodeproj

# 2. In Xcode: select the "Printables" scheme + an iPhone simulator → ⌘R

# 3. On first launch the app shows onboarding, then asks for your OpenAI API key.
#    Get one at: https://platform.openai.com/api-keys
#    Paste it in Settings → OpenAI API key → Save.
```

The project is fully self-contained — no CocoaPods, no Swift Package dependencies, just the iOS SDK + the system PDFKit framework.

---

## What it does

1. **Take or upload a photo** — apple, fire truck, family dog, anything.
2. **Tell it what to teach** — letter sounds, counting, healthy eating, safety, animal habitats, or any custom topic.
3. **Generate** — OpenAI Vision identifies the subject and writes age-appropriate learning content as strict JSON, then GPT Image renders the worksheet.
4. **Render** — `PDFRenderer` lays out a single-page Letter or A4 PDF using `UIGraphicsPDFRenderer`. Sections include:
   - Cover with hero photo + learning-goal chips
   - Trace the word
   - Count the items
   - Color it in (with swatches)
   - Draw your own
   - Word bank (vocabulary)
   - "Let's chat" discussion questions
   - "Did you know?" fun fact
   - Grown-up tip
5. **Print, share, save** — `UIPrintInteractionController` for AirPrint, `UIActivityViewController` for share/save to Files, Messages, Mail, etc.
6. **Library** — local SQLite-free archive in `Documents/worksheets.json` with thumbnail cards.

---

## Architecture

```
Printables/
├── App/
│   ├── PrintablesApp.swift        — App entry, NavBar appearance
│   └── RootView.swift             — TabView: Create / Library / Settings
├── Models/
│   ├── AppTheme.swift             — Colors, fonts, decorative dots
│   ├── AppSettings.swift          — API key, paper size, model — Keychain + AppStorage
│   └── Worksheet.swift            — Worksheet + WorksheetContent + Vocabulary
├── Services/
│   ├── KeychainStore.swift        — Secure API key storage
│   ├── OpenAIImageService.swift   — OpenAI vision + image generation
│   ├── PDFRenderer.swift          — PDFKit rendering of the worksheet design
│   ├── ImageStore.swift           — Photo & PDF disk persistence in Documents/
│   ├── WorksheetStore.swift       — JSON-backed @MainActor ObservableObject
│   └── WorksheetGenerator.swift   — Orchestrator with .analyzing/.writing/.rendering/.done stages
└── Views/
    ├── HomeView.swift             — Create tab matching reference design
    ├── LibraryView.swift          — Saved worksheets grid
    ├── SettingsView.swift         — API key, paper, model
    ├── OnboardingView.swift       — 3-screen first-run flow
    ├── GenerationProgressView.swift — Animated loading
    ├── WorksheetPreviewView.swift — PDFKit preview + Share + Print
    └── Components/
        ├── PrimaryButton.swift
        ├── IdeaChip.swift
        ├── CameraPicker.swift     — UIImagePickerController wrapper
        ├── PDFPreview.swift       — PDFView wrapper + ShareSheet
        └── FlowLayout.swift       — Custom Layout for wrapping chips
```

### Key design choices

- **No backend.** The app calls OpenAI directly using the operator's API key stored in the device Keychain. Cheap to ship, no server to run, but means every user needs their own key. (See `App Store launch` section below for the production-server version.)
- **Deterministic Xcode project.** `scripts/generate_xcodeproj.py` regenerates `project.pbxproj` with stable hashed UUIDs. Drop a new `.swift` file in `Printables/` and re-run the script — no Xcode drag-and-drop needed, no merge conflicts.
- **Pure SwiftUI, iOS 17 minimum.** No third-party dependencies. PDFKit, PhotosUI, AVFoundation are stock.
- **Robust JSON parsing.** OpenAI is prompted for strict JSON; `OpenAIImageService.extractJSONObject` finds and balances the first JSON object even if the model wraps it in prose or markdown fences.
- **Image downsizing.** Photos are downsized to 1024px max dimension and JPEG-compressed at 0.85 before being base64-encoded — keeps the API request small and fast.

---

## Generating the project file

If you add or rename Swift files, regenerate the Xcode project:

```bash
python3 scripts/generate_xcodeproj.py
```

This rebuilds `Printables.xcodeproj/project.pbxproj` from the current source tree with deterministic UUIDs (SHA-1 prefix of the path), so re-runs are reproducible and the file diffs cleanly in git.

---

## Generating the app icon

```bash
pip install Pillow
python3 scripts/generate_icon.py
```

Writes `Printables/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png`.

Tweak `scripts/generate_icon.py` to change the brand mark — colors come from the same palette as the app theme.

---

## App Store launch checklist

The app currently ships with the API-key-in-Keychain pattern, which is acceptable for TestFlight / personal use / a small group of users. To launch to the App Store at scale, you'll want a server-side proxy. The architecture supports both — only `OpenAIImageService.swift` needs to change.

### Step 1 — Apple Developer enrollment
- [ ] Apple Developer Program membership ($99/yr)
- [ ] App Store Connect: create a new app record
- [ ] Bundle ID: change `PRODUCT_BUNDLE_IDENTIFIER` in `scripts/generate_xcodeproj.py` from `com.printables.little-learners` to your own (e.g. `com.yourcompany.printables`)
- [ ] Re-run `python3 scripts/generate_xcodeproj.py`
- [ ] In Xcode: Signing & Capabilities → set your Team

### Step 2 — Replace API key entry with a server proxy (recommended)
The current `OpenAIImageService.swift` POSTs directly to OpenAI using a user-provided key. For App Store, swap it for a small backend (Cloudflare Worker, Vercel function, AWS Lambda — anything with HTTPS) that:
1. Receives `{ image: base64, goal: string }` from the app
2. Verifies the user (StoreKit subscription receipt, Sign in with Apple, or anonymous device ID + rate limit)
3. Calls OpenAI with your team's key
4. Returns the same `WorksheetContent` JSON

Then in `OpenAIImageService.swift`, replace the endpoint, headers, and request shape. Everything downstream stays the same.

### Step 3 — Monetization (optional)
The app is structured to accept either pattern:

| Pattern | Implementation |
|---------|----------------|
| Free + BYO key | What ships today. Zero infra. |
| One-time purchase | StoreKit 2 in-app purchase, then call server proxy |
| Subscription | StoreKit 2 with weekly/monthly tier, count worksheets per month |
| Free tier + paid Pro | 3 worksheets free, then paywall |

### Step 4 — Required App Store assets
- [ ] **App icon** — already generated (1024×1024). Asset catalog handles all sizes.
- [ ] **Screenshots** — 6.7", 6.5", 5.5" iPhone + 12.9" iPad. Use `xcrun simctl io booted screenshot` for the simulator.
- [ ] **App preview video** (optional but recommended) — 30s screen recording.
- [ ] **Privacy policy URL** — required. Disclose: photos are sent to OpenAI for processing; API key stored locally in Keychain; no analytics by default.
- [ ] **Support URL** — required.
- [ ] **App description, keywords, what's new** — App Store Connect metadata.

### Step 5 — Privacy + compliance
- [x] `NSCameraUsageDescription` — set in Info.plist
- [x] `NSPhotoLibraryUsageDescription` — set in Info.plist
- [x] `NSPhotoLibraryAddUsageDescription` — set in Info.plist
- [x] `ITSAppUsesNonExemptEncryption = false` — no custom crypto, only TLS
- [ ] App Privacy disclosure in App Store Connect:
  - Photos: collected for the function the user explicitly requests; NOT linked to identity; NOT used for tracking
  - API key (if BYO model): stored locally only; NOT collected by you
- [ ] If targeting kids under 13: enable the **Kids Category** flag and follow Apple's Kids guidelines (no third-party analytics, no behavioral ads, parental gates)

### Step 6 — Pre-submission validation
```bash
# Archive build
xcodebuild -project Printables.xcodeproj -scheme Printables \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/Printables.xcarchive archive

# Validate
xcodebuild -exportArchive -archivePath build/Printables.xcarchive \
  -exportPath build/ -exportOptionsPlist ExportOptions.plist
```

Then upload through Xcode's Organizer or `xcrun altool`.

### Step 7 — Review notes for Apple
- Mention: photos are sent only to OpenAI's API for content generation
- Mention: BYO API key pattern (if you keep it) — Apple sometimes asks about IAP requirement; explain it's a developer-tier convenience, not a paid feature
- Test account credentials: not needed (no login)

---

## Development tips

### Run on a simulator
```bash
xcodebuild -project Printables.xcodeproj -scheme Printables \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5' \
  -configuration Debug build
```

### Install and launch on the booted simulator
```bash
APP=$(find ~/Library/Developer/Xcode/DerivedData/Printables-*/Build/Products/Debug-iphonesimulator -name "Printables.app" -type d | head -1)
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.printables.little-learners
```

### Drag a photo into the simulator photo library
Just drag-and-drop any image file onto the Simulator window — it auto-adds to Photos.

### Reset the app data
```bash
xcrun simctl uninstall booted com.printables.little-learners
```

---

## Roadmap ideas

- **Multi-page worksheets** for older kids (counting → addition → simple word problems)
- **Multiple languages** — prompt OpenAI to write content in Spanish, French, Mandarin
- **Themes** — switch the PDF palette (pastel, monochrome high-contrast, dark-on-light, sticker pack)
- **Sticker reward sheet** that prints alongside the worksheet
- **Voice tutor** mode — read the worksheet aloud using `AVSpeechSynthesizer`
- **iCloud sync** so a parent on iPad and a teacher on iPhone share a library
- **Apple Pencil** annotations on top of the PDF preview for the child to draw inside the app
- **Print credits** — bulk pre-generate weekly packs

---

## License

© 2026 Chris DiMarco. All rights reserved. The source is published for portfolio purposes; reach out before reusing or redistributing it.
