# ZenJournal KPI Dashboard & Milestones

> Generated: 2026-03-18 | Source: MVP Report Section 12

---

## KPI Dashboard

| KPI | M1 | M3 | M6 | M12 |
|-----|-----|-----|-----|------|
| Downloads (cumulative) | 1,000 | 5,000 | 15,000 | 50,000 |
| MAU | 600 | 2,500 | 8,000 | 25,000 |
| D1 Retention | 40% | 45% | 50% | 50% |
| D7 Retention | 20% | 25% | 30% | 30% |
| D30 Retention | 8% | 12% | 15% | 18% |
| Paid Conversion | 2% | 4% | 6% | 7% |
| MRR | $60 | $500 | $2,400 | $8,750 |
| App Rating | 4.3+ | 4.5+ | 4.6+ | 4.7+ |
| ARPU (monthly) | $0.10 | $0.20 | $0.30 | $0.35 |

### MRR Calculation (M12 Optimistic)

- MAU 25,000 x 7% conversion = 1,750 paid users
- Monthly plan: 1,750 x 40% x $4.99 = **$3,493**
- Annual plan (monthly equiv): 1,750 x 55% x $29.99/12 = **$2,405**
- Lifetime (amortized): 1,750 x 5% x $79.99/12 = **$583**
- **Total MRR: ~$6,481 (conservative) ~ $8,750 (optimistic)**

---

## Kill Criteria

Conditions under which the project should be paused or terminated.

| Criterion | Threshold | Evaluation Point |
|-----------|-----------|------------------|
| D1 Retention | < 25% | M2 |
| Paid Conversion | < 1% | M3 |
| MRR | < $200 | M4 |
| App Rating | < 3.5 | Ongoing |
| CPI | > $5.00 (sustained) | M3 |

### Decision Framework

1. **Single kill criterion triggered** -- Investigate root cause, run A/B tests, allow 2-week remediation window.
2. **Two or more kill criteria triggered** -- Escalate to full review. Consider pivot or feature overhaul.
3. **Three or more for 4+ weeks** -- Project stop. Conduct post-mortem and document learnings.

---

## Milestones

| Timeframe | Milestone | Success Indicators |
|-----------|-----------|--------------------|
| **M1** | MVP Launch + First 100 Paid Users | Downloads 1K, Rating 4.0+ |
| **M3** | Product-Market Fit Validation | D30 Retention 12%+, NPS 40+ |
| **M6** | Revenue Stabilization | MRR $2K+, CAC < LTV/3 |
| **M12** | Growth Trajectory | MRR $8K+, Organic ratio 60%+ |

### Tracking Cadence

| Metric Category | Review Frequency | Tool |
|-----------------|-----------------|------|
| Downloads / MAU / Retention | Daily (dashboard) | Firebase Analytics |
| MRR / Conversion / ARPU | Weekly | RevenueCat Dashboard |
| App Rating / Reviews | Daily (alerts) | App Store Connect / Play Console |
| CPI / Ad ROAS | Weekly | Google Ads / Apple Search Ads |
| Cohort Analysis | Bi-weekly | Firebase + Custom queries |

### Revenue Milestones (Ad Revenue Projection)

Based on MAU 10K free users:

| Ad Type | Calculation | Monthly Revenue |
|---------|-------------|-----------------|
| Banner | 10K x 3 imp/day x 30d x $2.00 CPM | $1,800 |
| Interstitial | 10K x 0.33/day x 30d x $8.00 CPM | $792 |
| Rewarded | 10K x 0.1/day x 30d x $14.00 CPM | $420 |
| **Total** | | **~$3,012/mo** |
