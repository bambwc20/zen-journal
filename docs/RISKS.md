# ZenJournal Risk Matrix & Mitigation

> Generated: 2026-03-18 | Source: MVP Report Section 13

---

## Risk Matrix

| # | Risk | Probability | Impact | Risk Score |
|---|------|-------------|--------|------------|
| 1 | AI API cost spike (usage growth) | Medium | High | **High** |
| 2 | Competitors add AI features (Google Journal, etc.) | High | Medium | **High** |
| 3 | Privacy/data breach (journal data leak) | Low | Very High | **High** |
| 4 | Low D7 retention (habit formation failure) | Medium | High | **High** |
| 5 | Subscription fatigue (market-wide) | Medium | Medium | **Medium** |
| 6 | App Store AI policy changes | Low | High | **Medium** |

---

## Detailed Risk Response Strategies

### Risk 1: AI API Cost Spike

**Probability:** Medium | **Impact:** High

**Root Cause:** User growth outpaces revenue; per-user AI cost exceeds ARPU.

**Mitigation:**
- Use Claude Haiku model ($0.25/1M input tokens) -- lowest cost tier
- Implement aggressive caching: identical prompts within 24h return cached responses
- Enforce daily API call limits per user (free: 2/week, paid: 10/day)
- Batch context window: send only last 7 days of entries (not full history)
- Set budget alerts at $100/day, $2,000/month

**Monitoring:**
- Track monthly API cost per active user (target: < $0.05/user/month)
- Dashboard: daily API spend vs. revenue ratio
- Alert threshold: API cost > 15% of MRR

---

### Risk 2: Competitor AI Feature Addition

**Probability:** High | **Impact:** Medium

**Root Cause:** Large players (Google, Apple) integrate AI journaling natively.

**Mitigation:**
- Differentiate on personalization depth (7-day context window, pattern tracking)
- Build data moat: users accumulate history, increasing switching cost
- Community and brand loyalty through consistent quality
- Ship features faster than enterprise competitors (indie advantage)
- Focus on privacy narrative (local encryption vs. big tech cloud storage)

**Monitoring:**
- Monthly competitive feature audit
- Track competitor app updates and reviews
- Monitor keyword ranking changes in ASO

---

### Risk 3: Privacy / Data Breach

**Probability:** Low | **Impact:** Very High

**Root Cause:** Journal data is highly sensitive; breach would be catastrophic for trust.

**Mitigation:**
- SQLCipher AES-256 encryption for local DB (PRAGMA key on every open)
- Server never stores raw journal text -- only receives for AI processing, discards after response
- E2E encryption for cloud backups
- No analytics on journal content (only metadata: word count, mood level)
- Privacy policy prominently displayed; GDPR/CCPA compliant

**Monitoring:**
- Quarterly security audit
- Dependency vulnerability scanning (Dependabot)
- User reports / app review sentiment analysis

---

### Risk 4: Low D7 Retention

**Probability:** Medium | **Impact:** High

**Root Cause:** Users don't form journaling habit within first week.

**Mitigation:**
- Optimized onboarding: set reminder time, first entry within 60 seconds
- Streak system with emotional design (gentle, not punitive)
- Push notification A/B testing (timing, tone, frequency)
- AI reflection as "reward" after writing -- immediate value delivery
- Daily prompts reduce blank-page anxiety

**Monitoring:**
- Weekly cohort retention analysis (D1, D3, D7, D14, D30)
- Onboarding funnel drop-off tracking
- A/B test results review bi-weekly

---

### Risk 5: Subscription Fatigue

**Probability:** Medium | **Impact:** Medium

**Root Cause:** Users already subscribe to multiple apps; reluctant to add another.

**Mitigation:**
- Lifetime plan ($79.99) as primary conversion path for price-sensitive users
- Keep free tier genuinely useful (not crippled)
- Communicate ongoing value: weekly AI reports, new prompt packs
- Annual plan discount (40% off vs. monthly) -- reduce perceived monthly cost
- Consider one-time "Pro Lite" IAP if subscription conversion stalls

**Monitoring:**
- Subscription cancellation reasons (in-app survey)
- Free-to-paid conversion funnel analysis
- Churn rate by plan type (monthly vs. annual vs. lifetime)

---

### Risk 6: App Store AI Policy Changes

**Probability:** Low | **Impact:** High

**Root Cause:** Apple/Google may restrict AI-generated content or require disclosures.

**Mitigation:**
- Server-side AI processing (no on-device model dependency)
- AI responses clearly labeled as "AI-generated reflection"
- Architecture allows swapping LLM provider without app update
- Maintain compliance documentation for review team
- Follow Apple/Google developer news proactively

**Monitoring:**
- Apple WWDC and Google I/O policy announcements
- Developer forum and blog tracking
- App review rejection pattern monitoring

---

## Contingency Plan Summary

| Trigger | Action | Timeline |
|---------|--------|----------|
| API cost > 20% of MRR | Switch to lower-tier model, increase caching | 48 hours |
| Major competitor launches AI journal | Accelerate differentiation roadmap | 2 weeks |
| Data breach detected | Incident response, user notification, audit | Immediate |
| D7 retention < 15% for 3 weeks | Onboarding redesign sprint | 1 week |
| Monthly churn > 15% | Retention campaign + pricing review | 1 week |
| App rejected for AI policy | Server-side adjustment, resubmit | 3 days |
