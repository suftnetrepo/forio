# Forio — App Store Metadata
## Suftnet Ltd

---

## App Information

**Name:** Forio – AI CV & Cover Letter

**Subtitle (30 chars max):**
AI-tailored CVs in seconds

**Bundle ID:** com.suftnet.forio

**SKU:** suftnet-forio-001

**Primary Category:** Productivity

**Secondary Category:** Business

---

## Description (4000 chars max)

Land your dream job with a CV that's tailored to every single role — powered by GPT-4o AI.

Forio reads any job description and instantly generates a professional CV and cover letter matched to that specific role, using your own experience and skills.

**Perfect for:**
• Recent graduates looking for their first job
• Professionals ready for their next career move
• Career changers pivoting to a new industry
• Anyone returning to work after a break

**How it works:**
1. Set up your profile once — import your existing CV or build from scratch in minutes
2. Paste or scan any job description from LinkedIn, Indeed, or anywhere
3. Forio AI tailors your CV and cover letter to match the role
4. Export a professional PDF and apply with confidence

**What makes Forio different:**
Forio doesn't give you a generic CV template. It actually reads the job description, finds the keywords, matches them to your experience, and rewrites your profile to fit. Every CV it generates is unique to that job.

**AI that understands your situation:**
Whether you're a fresh graduate with no experience, an experienced professional looking to move up, a career changer bridging two industries, or returning to work after a break — Forio adapts its language and structure to tell your story in the best possible way.

**5 professional templates:**
Choose from Classic Navy, Clean Minimal, Bold Two-Column, Executive Gold, and Fresh Start — all ATS-safe so your CV gets past automated screening systems.

**What you get with every CV:**
• Tailored CV matched to the job description
• Professional cover letter included
• Keyword match score so you know how well you fit
• AI insights explaining exactly what was changed
• Export as PDF or share instantly

**Free to try:**
Generate 3 complete CVs for free. No credit card required.

**Forio Premium — unlimited everything:**
• Unlimited CV and cover letter generation
• All 5 premium templates
• Priority AI generation

---

## Keywords (100 chars max)
cv builder,resume,cover letter,job application,ai cv,career,graduate,job search,resume builder,pdf

---

## Support URL
https://suftnet.com/support

## Marketing URL
https://suftnet.com/forio

## Privacy Policy URL
https://suftnet.com/forio/privacy

---

## Version 1.0 Release Notes
First release of Forio — AI CV & Cover Letter Builder.

---

## Age Rating
4+ (no objectionable content)

---

## Pricing
Free with In-App Purchases:
- Forio Premium Monthly — £5.99/month
- Forio Premium Yearly — £29.99/year
- Forio Premium Lifetime — £59.99 (one-time)

---

## Review Notes for Apple

**Test account:** Not required — the app does not require login.

**What to test:**
1. Launch app → complete onboarding (select persona → import or build profile)
2. On dashboard tap "Make my first CV"
3. Enter a job title, company, and paste any job description text
4. Tap "Generate with AI" — the app calls OpenAI GPT-4o to generate a CV
5. View the generated CV and cover letter on the output screen
6. Tap "Export PDF" to generate and share a PDF
7. Tap the gear icon → Settings to view and edit profile

**IAP testing:** Use sandbox credentials to test Monthly, Yearly, and Lifetime purchases via RevenueCat.

**Network requirement:** The app requires an internet connection for AI generation (OpenAI API). All other features work offline.

**Special notes:**
- Camera permission is requested when the user taps "Scan CV" or "Scan job description"
- No user account or login is required
- All data is stored locally on device via SwiftData

---

## Screenshot Plan (6.7" iPhone — required)

1. **Splash / hero** — Forio logo + tagline "AI-tailored CVs in seconds"
2. **Persona picker** — "Where are you right now?" with 4 options
3. **Job input** — Job description pasted, Generate button prominent
4. **Generation progress** — Animated AI generating screen
5. **CV output** — Generated CV with match score and AI insights
6. **PDF export** — Share sheet with exported PDF

---

## TestFlight Notes

Before submitting to TestFlight:
1. Set deployment target to iOS 17.0 minimum
2. Confirm RevenueCat app entry created for com.suftnet.forio (separate from Revvo)
3. Update REVENUECAT_API_KEY in Config.xcconfig with Forio-specific key
4. Add App Store Connect IAP entries matching RevenueCat offering IDs
5. Confirm camera usage description appears in Info.plist
6. Archive → Distribute → App Store Connect → Upload
7. Add internal testers in TestFlight before external beta
