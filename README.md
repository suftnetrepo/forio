# Forio — AI CV & Cover Letter Builder
### by Suftnet Ltd

---

## Sprint 1 Scaffold

This is the Sprint 1 scaffold. All models, services, and the onboarding flow are wired up and ready to run.

---

## Setup Steps

### 1. Create the Xcode project

1. Open Xcode → **New Project** → iOS → App
2. Product Name: `Forio`
3. Bundle ID: `com.suftnet.forio`
4. Interface: SwiftUI
5. Storage: SwiftData
6. **Uncheck** "Include Tests" (or keep — doesn't matter)
7. Save to a folder, then **copy all files from this zip into the project folder**, replacing any Xcode-generated stubs

### 2. Add Swift packages

In Xcode → File → Add Package Dependencies:

| Package | URL |
|---|---|
| RevenueCat | `https://github.com/RevenueCat/purchases-ios` |

> **Note:** LaTeXSwiftUI and VisionKit are system frameworks — no package needed for VisionKit.

### 3. Wire up Config.xcconfig

1. In Xcode, select your project root → Info tab → Configurations
2. For both **Debug** and **Release**, set the configuration file to `Forio/Config.xcconfig`
3. This makes `OPENAI_API_KEY` and `REVENUECAT_API_KEY` available via `Bundle.main.infoDictionary`

### 4. Enable camera entitlement

In Xcode → target → Signing & Capabilities → add **Privacy - Camera Usage Description**
(already in Info.plist — just confirm it appears in the target)

### 5. Add Forio to your RevenueCat dashboard

1. Log in to app.revenuecat.com
2. Add new app → iOS → Bundle ID: `com.suftnet.forio`
3. Create entitlement ID: `premium`
4. Create offerings: Monthly, Yearly, Lifetime
5. The existing `REVENUECAT_API_KEY` in Config.xcconfig is your Revvo key — **create a new one for Forio** in RevenueCat and update Config.xcconfig

### 6. Build & run

Hit ▶ — you should see the Forio onboarding flow on the simulator.

---

## File Map

```
Forio/
├── ForioApp.swift              ← App entry, SwiftData container, RevenueCat init
├── AppTheme.swift              ← All colours, fonts, button styles
├── Constants.swift             ← API endpoints, keys, limits
├── Config.xcconfig             ← API keys (gitignored — never commit)
├── Info.plist                  ← Reads keys from xcconfig
│
├── Models/
│   ├── UserProfile.swift       ← SwiftData: user profile + UserPersona enum
│   ├── CVTemplate.swift        ← CVTemplate enum (5 templates)
│   ├── JobApplication.swift    ← SwiftData: job + status
│   └── GeneratedDocument.swift ← SwiftData: CV + cover letter + match score
│
├── Services/
│   ├── AIService.swift         ← GPT-4o: extraction + generation (from Revvo AI.swift)
│   ├── PromptBuilder.swift     ← Persona-aware prompt construction
│   └── PurchaseService.swift   ← RevenueCat (from Revvo, updated for 3-gen free tier)
│
├── Utils/
│   ├── Color+Hex.swift         ← Hex colour init (from Revvo verbatim)
│   ├── DocumentScannerView.swift ← VisionKit wrapper (from Revvo verbatim)
│   └── SkillChipView.swift     ← Tappable skill chips + preset skills per persona
│
└── Views/
    ├── Home/
    │   ├── ContentView.swift   ← Root: onboarding gate → HomeView
    │   └── HomeView.swift      ← Dashboard placeholder (Sprint 9 fills this out)
    ├── Onboarding/
    │   └── OnboardingView.swift ← Welcome → Persona picker → Import choice
    └── Paywall/
        └── PaywallView.swift   ← RevenueCat paywall, gold Forio branding
```

---

## Sprint Roadmap

| Sprint | Focus |
|---|---|
| **1** ✅ | Project setup, models, onboarding, paywall scaffold |
| 2 | CV import — VisionKit scan + PDF upload + GPT-4o extraction |
| 3 | Manual profile builder — persona-adaptive questions |
| 4 | Job input screen + AI CV generation |
| 5 | Output view + CV/cover letter tabs + edit |
| 6 | PDF export — 5 templates via PDFKit |
| 7 | Template picker + Pro gate |
| 8 | Dashboard, history, settings |
| 9 | Polish, App Store metadata, TestFlight |

---

## Notes

- `Config.xcconfig` is in `.gitignore` — never commit it to a public repo
- The OpenAI key in Config.xcconfig is your existing Revvo key — it will work immediately
- Create a **new** RevenueCat app entry for Forio (separate from Revvo) before going to TestFlight
- Support URL: https://suftnet.com/support
