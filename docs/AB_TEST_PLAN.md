# A/B Test Plan — ZenJournal

## Test 1: Onboarding Length

| Item | Detail |
|------|--------|
| **Hypothesis** | A shorter onboarding (3 steps) will have higher completion rate but a longer onboarding (5 steps) will produce higher D1 retention due to better goal-setting. |
| **Variant A** | 3-step onboarding: (1) Welcome + name, (2) Set reminder time, (3) Pro trial CTA |
| **Variant B** | 5-step onboarding: (1) Welcome + name, (2) Journaling goal selection, (3) Preferred mood categories, (4) Set reminder time, (5) Pro trial CTA |
| **Primary KPI** | D1 journal entry completion rate |
| **Secondary KPIs** | Onboarding completion rate, D7 retention, Pro trial start rate |
| **Traffic Split** | 50/50 |
| **Sample Size** | 500 users per variant (1,000 total) |
| **Duration** | 2-4 weeks (or until statistical significance at p < 0.05) |
| **Segment** | All new users |
| **Implementation** | Firebase Remote Config flag: `onboarding_variant` = `3step` or `5step` |
| **Success Criteria** | Variant wins if D1 entry rate is >= 5% higher with p < 0.05 |

---

## Test 2: Paywall Format

| Item | Detail |
|------|--------|
| **Hypothesis** | A full-screen paywall with feature comparison will convert better than a bottom-sheet paywall, because users see more value before deciding. |
| **Variant A** | Bottom-sheet modal: Price cards + single CTA + dismiss by swipe |
| **Variant B** | Full-screen paywall: Feature comparison table + testimonials + price cards + CTA |
| **Primary KPI** | Free-to-paid conversion rate |
| **Secondary KPIs** | Paywall dismiss rate, time on paywall, plan selection distribution |
| **Traffic Split** | 50/50 |
| **Sample Size** | 300 paywall views per variant (600 total) |
| **Duration** | 3-6 weeks |
| **Segment** | Free users who trigger any bridge point |
| **Implementation** | Firebase Remote Config flag: `paywall_variant` = `bottomsheet` or `fullscreen` |
| **Success Criteria** | Variant wins if conversion rate is >= 1.5 percentage points higher with p < 0.05 |

---

## Test 3: AI Reflection Length

| Item | Detail |
|------|--------|
| **Hypothesis** | Longer, more detailed AI reflections (3 sections) will increase perceived value and drive higher return visits compared to short 1-line reflections. |
| **Variant A** | Short reflection: 1-line emotional summary (e.g., "You seem reflective and slightly anxious today.") |
| **Variant B** | Detailed reflection: 3 sections — Emotion Analysis (1-2 sentences), Pattern Insight (1-2 sentences), Action Suggestion (1 sentence) |
| **Primary KPI** | D7 return rate (users who come back to view reflection) |
| **Secondary KPIs** | "Helpful" tap rate, AI reflection request frequency, Pro conversion rate |
| **Traffic Split** | 50/50 |
| **Sample Size** | 400 AI reflections per variant (800 total) |
| **Duration** | 4 weeks |
| **Segment** | All users who request AI reflection |
| **Implementation** | Firebase Remote Config flag: `reflection_variant` = `short` or `detailed` |
| **Success Criteria** | Variant wins if D7 return rate is >= 3% higher with p < 0.05 |

---

## Test 4: Annual Pricing

| Item | Detail |
|------|--------|
| **Hypothesis** | A lower annual price ($24.99/yr) will increase subscription volume enough to offset the per-user revenue decrease, resulting in higher total MRR. |
| **Variant A** | $29.99/yr (current, = $2.49/mo) |
| **Variant B** | $24.99/yr (= $2.08/mo, 50% off monthly) |
| **Primary KPI** | LTV (projected 12-month revenue per converting user) |
| **Secondary KPIs** | Conversion rate, plan selection (monthly vs annual vs lifetime), churn rate at renewal |
| **Traffic Split** | 50/50 |
| **Sample Size** | 500 paywall views per variant (1,000 total) |
| **Duration** | 8-12 weeks (need renewal data) |
| **Segment** | Free users seeing paywall for first time |
| **Implementation** | RevenueCat offering: `annual_default` vs `annual_discounted` |
| **Success Criteria** | Variant wins if projected 12-month MRR per 1,000 users is >= 10% higher |
| **Note** | Must run long enough to capture first renewal cycle for churn comparison |

---

## Test 5: Prompt Display Format

| Item | Detail |
|------|--------|
| **Hypothesis** | Adding a calming image above the daily prompt text will increase prompt completion rate by creating a more inviting writing experience. |
| **Variant A** | Text-only prompt: Centered prompt text with minimal styling |
| **Variant B** | Image + text prompt: Nature/calm image header (from curated set of 30) + prompt text below |
| **Primary KPI** | Prompt completion rate (user writes entry after viewing prompt) |
| **Secondary KPIs** | Time to first keystroke, average entry word count, prompt skip rate |
| **Traffic Split** | 50/50 |
| **Sample Size** | 600 prompt views per variant (1,200 total) |
| **Duration** | 3-4 weeks |
| **Segment** | All users who view daily prompt |
| **Implementation** | Firebase Remote Config flag: `prompt_variant` = `text` or `image_text` |
| **Success Criteria** | Variant wins if completion rate is >= 5% higher with p < 0.05 |

---

## Test Priority & Schedule

| Priority | Test | Earliest Start | Dependency |
|----------|------|----------------|------------|
| 1 | Onboarding (3 vs 5 steps) | M1 launch | None |
| 2 | Paywall format | M1 launch | None (can run parallel with #1) |
| 3 | AI Reflection length | M2 | Need 800+ AI reflection events |
| 4 | Prompt display format | M2 | Need 1,200+ prompt views |
| 5 | Annual pricing | M3 | Need stable conversion baseline first |

## Analytics Setup Required

- Firebase Remote Config for variant assignment
- Firebase Analytics custom events:
  - `onboarding_completed` (with `variant` parameter)
  - `paywall_viewed`, `paywall_converted` (with `variant` parameter)
  - `ai_reflection_viewed`, `ai_reflection_helpful_tap` (with `variant` parameter)
  - `prompt_viewed`, `prompt_entry_started` (with `variant` parameter)
  - `subscription_started` (with `price_variant` parameter)
- RevenueCat for subscription/revenue tracking per variant
- Minimum p < 0.05 for statistical significance before declaring winner
- Use sequential testing (not fixed-horizon) to allow early stopping
