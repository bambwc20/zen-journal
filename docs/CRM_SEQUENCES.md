# CRM Push Notification Sequences — ZenJournal

## 1. Onboarding Sequence (D0–D30)

8 touchpoints designed to activate, engage, and convert new users.

| # | Timing | Title | Body | Purpose | Segment |
|---|--------|-------|------|---------|---------|
| 1 | D0 (install + 2h) | Welcome to ZenJournal! | Start your first journal entry today. Just 2 minutes to capture your day. | First entry activation | All new users |
| 2 | D1 (evening) | Your AI insight is ready | Yesterday's entry got an AI reflection. Tap to see what patterns it found. | AI value demonstration | Users who wrote D0 |
| 3 | D3 (evening) | 3-day streak! Keep going | You've journaled 3 days in a row. This momentum builds lasting habits. | Streak motivation | Active users |
| 4 | D5 (afternoon) | Pro trial ends in 2 days | Set up encrypted backup before your trial ends. Your data deserves protection. | Trial conversion nudge | Trial users |
| 5 | D7 (morning) | 7-day streak achieved! | Congratulations! Unlock your Weekly AI Report with Pro to see the full picture. | Paid conversion | Streak achievers |
| 6 | D14 (evening) | 2 weeks of emotions analyzed | Your 2-week mood patterns are in. Check your AI insights to understand your trends. | Re-engagement | All users |
| 7 | D21 (evening) | Your journaling style is unique | AI has learned your patterns over 3 weeks. Personalized prompts are getting smarter. | Value reinforcement | Active users |
| 8 | D30 (morning) | One month of journaling! | Export your month's journey as a PDF keepsake. Available with Pro. | Long-term conversion | All users |

### Implementation Notes
- D0 notification scheduled 2 hours after first app open (not install)
- D1–D30 calculated from first app open date
- Skip notifications if user has already converted to paid
- Skip D5 trial notification if user is not on a free trial
- All times are in user's local timezone

---

## 2. Dormant User Re-engagement

### 7-Day Inactive Sequence

| # | Timing | Title | Body | Purpose |
|---|--------|-------|------|---------|
| 1 | Day 7 inactive | We miss your journaling | Taking a break is okay. When you're ready, your journal is here waiting. | Gentle reminder |
| 2 | Day 10 inactive | A prompt just for you | "What's one small thing that made you smile this week?" — Try this gentle prompt. | Low-friction re-entry |

### 30-Day Inactive Sequence

| # | Timing | Title | Body | Purpose |
|---|--------|-------|------|---------|
| 1 | Day 30 inactive | Your journal is safe | Your entries are encrypted and secure. Come back anytime to continue your journey. | Data safety reassurance |
| 2 | Day 45 inactive | Fresh start? | Sometimes the best time to journal is after a break. No streak pressure — just write. | Remove guilt/pressure |

### Re-engagement Rules
- Maximum 2 dormant notifications per inactive period
- If user does not re-engage after 45-day notification, stop automated pushes
- Re-entering the app resets the dormant sequence
- Never send dormant notifications if user has disabled reminders

---

## 3. User Segment Strategies

### Power Writer
**Condition:** 5+ entries per week, 500+ characters average

| Strategy | Action | Timing |
|----------|--------|--------|
| Deep AI analysis | Push: "Your weekly deep analysis is ready — see patterns across 7 entries" | Weekly (Monday morning) |
| Annual plan upsell | Push: "Power writers save 40% with the annual plan. You've written {count} entries!" | After 30 entries |
| Export feature | Push: "Export your {count} entries as PDF — a beautiful record of your journey" | Monthly |
| Feature feedback | In-app: "As a power user, we'd love your input on new features" | Quarterly |

### Mood Tracker
**Condition:** Logs mood daily, but writes < 100 characters

| Strategy | Action | Timing |
|----------|--------|--------|
| Prompt encouragement | Push: "Today's prompt: '{prompt}' — even 1 sentence adds depth to your mood log" | Daily at reminder time |
| Quick entry | Push: "Just 30 seconds: How are you feeling and why? Your future self will thank you" | 2x/week |
| Mood insights | Push: "Your mood has been {trend} this week. AI found an interesting pattern" | Weekly |
| Gradual upgrade | Soft paywall: Detailed mood analytics (correlations, triggers) behind Pro | After 14 mood logs |

### Dormant
**Condition:** 7+ days no activity

| Strategy | Action | Timing |
|----------|--------|--------|
| Gentle re-engagement | See Dormant User Re-engagement sequences above | Day 7, 10, 30, 45 |
| Streak recovery | Push: "Your {streak}-day streak can still be saved! Use your free exemption" | Day 1-2 of inactivity |
| Reduced friction | Deep link directly to quick entry screen (not home) | All dormant pushes |

### Free Loyalist
**Condition:** 30+ days active, still on free plan

| Strategy | Action | Timing |
|----------|--------|--------|
| Lifetime deal | Push: "You've journaled for {days} days! Lifetime Pro is a one-time investment: $79.99" | Day 30, 60 |
| Limited offer | Push: "This week only: 30% off annual Pro. Your commitment deserves full features" | Quarterly |
| Value demonstration | Push: "You've hit the 30-day search limit {count} times. Pro unlocks your full history" | When search limit hit 3x |
| Social proof | Push: "{X}% of long-term users upgrade to Pro. See what you're missing" | Day 45 |

---

## 4. Subscription Churn Prevention

### Cancel Intent Detection
- User visits subscription management screen
- User searches "cancel" in settings
- User downgrades usage significantly (3+ days of no activity after daily usage)

### Churn Prevention Sequence

| # | Trigger | Action | Offer |
|---|---------|--------|-------|
| 1 | Cancel button tap | Show survey: "What could we improve?" | — |
| 2 | Cancel reason: "Too expensive" | Offer: 30% off annual plan renewal | $20.99/yr (was $29.99) |
| 3 | Cancel reason: "Don't use enough" | Offer: Downgrade to monthly at 50% off for 3 months | $2.49/mo for 3 months |
| 4 | Cancel reason: "Missing features" | Show roadmap + "Feature X is coming in {month}" | 1 month free extension |
| 5 | Cancel reason: "Found alternative" | Offer: Lifetime plan at 40% off ($47.99) | $47.99 one-time |
| 6 | Completed cancellation | D3 post-cancel: "We saved your data. Come back anytime" | — |
| 7 | Completed cancellation | D14 post-cancel: "New feature launched: {feature}. Restart Pro?" | First month free |

### Churn Prevention Rules
- Maximum 1 discount offer per cancellation attempt
- Discount offers expire in 48 hours
- Track offer acceptance rate by reason (optimize quarterly)
- Never show discount if user has received one in the past 90 days
- Log all churn interactions for analysis

---

## 5. Notification Delivery Rules

### Global Rules
- Respect system notification permissions (check before scheduling)
- Respect user's "Do Not Disturb" hours (default: 10 PM – 8 AM)
- Maximum 1 push notification per day (excluding user-set reminders)
- CRM notifications are lower priority than user-set journal reminders
- All CRM notifications are local (MVP); server-side FCM in v1.1

### Personalization
- Use user's name if available (from onboarding)
- Reference actual streak count in streak-related messages
- Reference actual entry count in milestone messages
- Adapt tone based on segment (Power Writer = data-driven, Mood Tracker = gentle)

### Opt-out
- Settings > Notifications > "Motivational messages" toggle
- Disabling stops all CRM sequences but keeps user-set reminders
- Re-enabling resumes sequence from current day offset
