# Forio — Pre-Submission Checklist
## Complete these before archiving for TestFlight

---

## Xcode Project

- [ ] Deployment target set to **iOS 17.0**
- [ ] Bundle ID confirmed as **com.suftnet.forio**
- [ ] Version **1.0**, Build **1**
- [ ] Display name set to **Forio**
- [ ] Signing & Capabilities → your Suftnet Ltd team selected
- [ ] Capabilities added: **In-App Purchase**
- [ ] `NSCameraUsageDescription` present in Info.plist ✅ (already set)
- [ ] `NSPhotoLibraryUsageDescription` present in Info.plist ✅ (already set)
- [ ] Config.xcconfig has correct keys (never committed to git) ✅

---

## RevenueCat

- [ ] New app created in RevenueCat dashboard for **com.suftnet.forio**
- [ ] Entitlement created: **premium**
- [ ] Products configured:
  - [ ] Monthly: `forio_premium_monthly`
  - [ ] Yearly: `forio_premium_yearly`
  - [ ] Lifetime: `forio_premium_lifetime`
- [ ] Offering created with all 3 packages
- [ ] New API key copied into `Config.xcconfig` → `REVENUECAT_API_KEY`

---

## App Store Connect

- [ ] New app created: **Forio – AI CV & Cover Letter**
- [ ] Bundle ID: **com.suftnet.forio**
- [ ] SKU: **suftnet-forio-001**
- [ ] In-App Purchases created (matching RevenueCat product IDs):
  - [ ] `forio_premium_monthly` — Auto-Renewable Subscription
  - [ ] `forio_premium_yearly` — Auto-Renewable Subscription
  - [ ] `forio_premium_lifetime` — Non-Consumable
- [ ] Subscription Group created: **Forio Premium**
- [ ] App description pasted from `AppStoreMetadata.md`
- [ ] Keywords entered (100 chars max)
- [ ] Support URL: https://suftnet.com/support
- [ ] Privacy Policy URL: https://suftnet.com/forio/privacy
- [ ] Privacy policy HTML uploaded to your hosting (suftnet.com)
- [ ] Age Rating: **4+**
- [ ] Screenshots prepared (6.7" required, 6.1" recommended)

---

## Final Build Checks

- [ ] Run on a **real device** (not just simulator)
- [ ] Test the full flow end-to-end on device:
  - [ ] Onboarding completes without errors
  - [ ] CV scan works (requires physical device for camera)
  - [ ] GPT-4o generation completes and returns content
  - [ ] PDF export opens share sheet
  - [ ] Paywall loads products from RevenueCat sandbox
  - [ ] Sandbox purchase completes and unlocks premium
  - [ ] Restore purchases works
  - [ ] Settings → Reset all data returns to onboarding
- [ ] Test on iOS 17 device if possible (minimum deployment target)
- [ ] No crashes in Xcode console during full flow
- [ ] Memory usage stable during generation (no leaks)

---

## Archive & Upload

```
Xcode → Product → Archive
→ Distribute App
→ App Store Connect
→ Upload
→ TestFlight → Internal Testing
→ Add yourself as internal tester
→ Install via TestFlight app
```

---

## After TestFlight Approval

- [ ] Test on TestFlight build (not simulator)
- [ ] Submit for App Store Review
- [ ] Add review notes (copy from AppStoreMetadata.md)
- [ ] Set release: **Manual release** (so you control go-live timing)

---

## Go Live 🚀

Congratulations Abel — Forio is ready to ship.

Two apps on the App Store. 🔥
