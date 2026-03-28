# Ad Unit IDs — ZenJournal

## Current Test IDs (Google Official)

These are **test-only** IDs provided by Google. They will show sample ads and
never generate real revenue.

### Banner

| Platform | Ad Unit ID |
|----------|-----------|
| Android  | `ca-app-pub-3940256099942544/6300978111` |
| iOS      | `ca-app-pub-3940256099942544/2934735716` |

### Interstitial

| Platform | Ad Unit ID |
|----------|-----------|
| Android  | `ca-app-pub-3940256099942544/1033173712` |
| iOS      | `ca-app-pub-3940256099942544/4411468910` |

### Native

| Platform | Ad Unit ID |
|----------|-----------|
| Android  | `ca-app-pub-3940256099942544/2247696110` |
| iOS      | `ca-app-pub-3940256099942544/3986624511` |

### Rewarded

| Platform | Ad Unit ID |
|----------|-----------|
| Android  | `ca-app-pub-3940256099942544/5224354917` |
| iOS      | `ca-app-pub-3940256099942544/1712485313` |

### App IDs (for manifests)

| Platform | App ID |
|----------|--------|
| Android  | `ca-app-pub-3940256099942544~3347511713` |
| iOS      | `ca-app-pub-3940256099942544~1458002511` |

## Production Replacement Guide

1. Create ad units in the [AdMob Console](https://admob.google.com/).
2. Replace the IDs in:
   - `lib/features/zen_journal/presentation/providers/ad_providers.dart`
     (`AdUnitIds` class)
   - `lib/core/ads/ad_widgets.dart` (banner `_adUnitId` getter)
   - `android/app/src/main/AndroidManifest.xml` (App ID meta-data)
   - `ios/Runner/Info.plist` (`GADApplicationIdentifier`)
3. **Never** commit production ad unit IDs to a public repository. Consider
   using environment variables or a build config (e.g., `--dart-define`).

## Ad Placement Summary

| Ad Type       | Placement                              | Trigger                        |
|---------------|----------------------------------------|--------------------------------|
| Banner        | Journal list screen — bottom           | Always visible (free users)    |
| Interstitial  | After journal save                     | Every 3rd save (free users)    |
| Native        | Between daily prompts in prompt list   | Always visible (free users)    |
| Rewarded      | AI reflection screen — extra reflection| User-initiated (free users)    |

## Expected eCPM (US Market)

| Ad Type       | eCPM Range      |
|---------------|-----------------|
| Banner        | $1.50 - $2.50   |
| Interstitial  | $6.00 - $10.00  |
| Native        | $2.00 - $3.50   |
| Rewarded      | $10.00 - $18.00 |
