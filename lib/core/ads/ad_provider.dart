import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../subscription/subscription_provider.dart';

part 'ad_provider.g.dart';

@riverpod
bool showAds(Ref ref) {
  final subscription = ref.watch(customerInfoProvider);
  return subscription.when(
    data: (info) => !info.entitlements.active.containsKey('premium'),
    loading: () => false,
    error: (_, __) => true,
  );
}

class AdService {
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  static BannerAd createBannerAd({
    required AdSize size,
    required String adUnitId,
    void Function()? onAdLoaded,
    void Function(LoadAdError)? onAdFailedToLoad,
  }) {
    return BannerAd(
      size: size,
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onAdLoaded?.call(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onAdFailedToLoad?.call(error);
        },
      ),
    );
  }
}
