import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:flutter_boilerplate/core/ads/ad_provider.dart';

part 'ad_providers.g.dart';

// ---------------------------------------------------------------------------
// Test Ad Unit IDs (Google official)
// Replace with production IDs before release — see docs/AD_UNIT_IDS.md
// ---------------------------------------------------------------------------

class AdUnitIds {
  AdUnitIds._();

  // Banner
  static String get banner => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  // Interstitial
  static String get interstitial => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  // Native
  static String get native => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/2247696110'
      : 'ca-app-pub-3940256099942544/3986624511';

  // Rewarded
  static String get rewarded => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';
}

// ---------------------------------------------------------------------------
// Interstitial counter — show interstitial every 3rd journal save
// ---------------------------------------------------------------------------

@riverpod
class InterstitialCounter extends _$InterstitialCounter {
  @override
  int build() => 0;

  /// Increments the save counter and returns true when an interstitial should
  /// be shown (every 3rd save).
  bool incrementAndCheck() {
    final showAds = ref.read(showAdsProvider);
    if (!showAds) return false;

    state = state + 1;
    if (state >= 3) {
      state = 0;
      return true;
    }
    return false;
  }

  void reset() => state = 0;
}

// ---------------------------------------------------------------------------
// Rewarded ad state
// ---------------------------------------------------------------------------

enum RewardedAdStatus { idle, loading, loaded, playing, rewarded, error }

@riverpod
class RewardedAdState extends _$RewardedAdState {
  RewardedAd? _rewardedAd;

  @override
  RewardedAdStatus build() => RewardedAdStatus.idle;

  /// Preloads a rewarded ad so it's ready to show.
  void loadAd() {
    final showAds = ref.read(showAdsProvider);
    if (!showAds) return;

    state = RewardedAdStatus.loading;

    RewardedAd.load(
      adUnitId: AdUnitIds.rewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          state = RewardedAdStatus.loaded;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              // Keep rewarded status if earned; otherwise go idle.
              if (state != RewardedAdStatus.rewarded) {
                state = RewardedAdStatus.idle;
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              state = RewardedAdStatus.error;
              debugPrint('RewardedAd failed to show: $error');
            },
          );
        },
        onAdFailedToLoad: (error) {
          state = RewardedAdStatus.error;
          debugPrint('RewardedAd failed to load: $error');
        },
      ),
    );
  }

  /// Shows the loaded rewarded ad. Returns a Future that completes with true
  /// if the user earned the reward, false otherwise.
  Future<bool> showAd() async {
    if (_rewardedAd == null || state != RewardedAdStatus.loaded) {
      return false;
    }

    state = RewardedAdStatus.playing;
    bool earned = false;

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        earned = true;
        state = RewardedAdStatus.rewarded;
      },
    );

    return earned;
  }

  /// Resets the state back to idle (call after consuming the reward).
  void consumeReward() {
    state = RewardedAdStatus.idle;
  }

  bool get isLoaded => state == RewardedAdStatus.loaded;
  bool get isRewarded => state == RewardedAdStatus.rewarded;
}

// ---------------------------------------------------------------------------
// Ad frequency limiter — ensures ads aren't shown too frequently
// ---------------------------------------------------------------------------

@riverpod
class AdFrequency extends _$AdFrequency {
  @override
  DateTime? build() => null;

  /// Returns true if enough time has passed since the last ad (minimum gap:
  /// [minGap], defaults to 60 seconds).
  bool canShowAd({Duration minGap = const Duration(seconds: 60)}) {
    final showAds = ref.read(showAdsProvider);
    if (!showAds) return false;

    final lastShown = state;
    if (lastShown == null) return true;
    return DateTime.now().difference(lastShown) >= minGap;
  }

  /// Records that an ad was just shown.
  void recordAdShown() {
    state = DateTime.now();
  }
}
