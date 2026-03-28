import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:flutter_boilerplate/core/ads/ad_provider.dart';
import 'package:flutter_boilerplate/core/ads/ad_widgets.dart';
import '../providers/ad_providers.dart';

// ---------------------------------------------------------------------------
// 1) JournalListBannerAd — banner ad at the bottom of the journal list
// ---------------------------------------------------------------------------

/// Wraps the core [AdBanner] for the journal list screen.
/// Displays a banner ad only for free users.
class JournalListBannerAd extends ConsumerWidget {
  const JournalListBannerAd({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAds = ref.watch(showAdsProvider);
    if (!showAds) return const SizedBox.shrink();

    return const SafeArea(
      child: AdBanner(size: AdSize.banner),
    );
  }
}

// ---------------------------------------------------------------------------
// 2) InterstitialAdManager — show interstitial after every 3rd journal save
// ---------------------------------------------------------------------------

/// Manages interstitial ad lifecycle.
/// Call [onJournalSaved] after each successful journal save.
class InterstitialAdManager {
  InterstitialAdManager._();

  static InterstitialAd? _interstitialAd;

  /// Preloads an interstitial ad.
  static void preload() {
    InterstitialAd.load(
      adUnitId: AdUnitIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              // Pre-load the next one
              preload();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              debugPrint('Interstitial failed to show: $error');
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed to load: $error');
        },
      ),
    );
  }

  /// Call this after each journal save.
  /// Uses the [InterstitialCounter] provider to decide whether to show an ad
  /// (every 3rd save). Also respects the [AdFrequency] limiter.
  static void onJournalSaved(WidgetRef ref) {
    final showAds = ref.read(showAdsProvider);
    if (!showAds) return;

    final shouldShow =
        ref.read(interstitialCounterProvider.notifier).incrementAndCheck();
    if (!shouldShow) return;

    final canShow = ref.read(adFrequencyProvider.notifier).canShowAd();
    if (!canShow) return;

    if (_interstitialAd != null) {
      ref.read(adFrequencyProvider.notifier).recordAdShown();
      _interstitialAd!.show();
    } else {
      // Ad wasn't ready — preload for next time.
      preload();
    }
  }
}

// ---------------------------------------------------------------------------
// 3) NativePromptAd — native ad displayed between daily prompts
// ---------------------------------------------------------------------------

/// A native ad widget designed to blend with the prompt list.
/// Shows only for free users.
class NativePromptAd extends ConsumerStatefulWidget {
  const NativePromptAd({super.key});

  @override
  ConsumerState<NativePromptAd> createState() => _NativePromptAdState();
}

class _NativePromptAdState extends ConsumerState<NativePromptAd> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: AdUnitIds.native,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('NativeAd failed to load: $error');
          if (mounted) setState(() => _isLoaded = false);
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Colors.white,
        cornerRadius: 16,
        callToActionTextStyle: NativeTemplateTextStyle(
          size: 14,
          textColor: Colors.white,
          backgroundColor: const Color(0xFF6B9B7B),
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          size: 14,
          textColor: Colors.black87,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          size: 12,
          textColor: Colors.black54,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showAds = ref.watch(showAdsProvider);

    if (!showAds || !_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      constraints: const BoxConstraints(
        minHeight: 90,
        maxHeight: 120,
      ),
      child: AdWidget(ad: _nativeAd!),
    );
  }
}

// ---------------------------------------------------------------------------
// 4) RewardedAdManager — rewarded ad for earning extra AI reflections
// ---------------------------------------------------------------------------

/// Helper widget / utility for showing a rewarded ad that grants an
/// extra AI reflection upon completion.
///
/// Usage from a screen:
/// ```dart
/// final earned = await RewardedAdManager.showForExtraReflection(ref);
/// if (earned) { /* grant extra AI reflection */ }
/// ```
class RewardedAdManager {
  RewardedAdManager._();

  /// Preloads a rewarded ad via the provider.
  static void preload(WidgetRef ref) {
    final showAds = ref.read(showAdsProvider);
    if (!showAds) return;
    ref.read(rewardedAdStateProvider.notifier).loadAd();
  }

  /// Shows the rewarded ad. Returns true if the user earned the reward.
  /// Must call [preload] before this method.
  static Future<bool> showForExtraReflection(WidgetRef ref) async {
    final showAds = ref.read(showAdsProvider);
    if (!showAds) return false;

    final canShow = ref.read(adFrequencyProvider.notifier).canShowAd(
          minGap: const Duration(seconds: 30),
        );
    if (!canShow) return false;

    final notifier = ref.read(rewardedAdStateProvider.notifier);
    final earned = await notifier.showAd();

    if (earned) {
      ref.read(adFrequencyProvider.notifier).recordAdShown();
      notifier.consumeReward();
    }

    return earned;
  }
}

// ---------------------------------------------------------------------------
// Convenience: a button widget that handles the full rewarded ad flow
// ---------------------------------------------------------------------------

/// A button that loads and shows a rewarded ad for earning an extra
/// AI reflection. Shows a loading indicator while the ad loads.
class RewardedAdButton extends ConsumerWidget {
  const RewardedAdButton({
    super.key,
    required this.onRewardEarned,
    this.label = 'Watch Ad for Extra Reflection',
  });

  final VoidCallback onRewardEarned;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAds = ref.watch(showAdsProvider);
    if (!showAds) return const SizedBox.shrink();

    final adStatus = ref.watch(rewardedAdStateProvider);

    return FilledButton.tonalIcon(
      onPressed: adStatus == RewardedAdStatus.loaded
          ? () async {
              final earned =
                  await RewardedAdManager.showForExtraReflection(ref);
              if (earned) {
                onRewardEarned();
              }
            }
          : adStatus == RewardedAdStatus.idle ||
                  adStatus == RewardedAdStatus.error
              ? () => RewardedAdManager.preload(ref)
              : null,
      icon: adStatus == RewardedAdStatus.loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.play_circle_outline),
      label: Text(
        adStatus == RewardedAdStatus.loading ? 'Loading...' : label,
      ),
    );
  }
}
