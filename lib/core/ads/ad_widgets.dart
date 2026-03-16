import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_provider.dart';

class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key, this.size = AdSize.banner});

  final AdSize size;

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  String get _adUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Test ID
    } else {
      return 'ca-app-pub-3940256099942544/2934735716'; // Test ID
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = AdService.createBannerAd(
      size: widget.size,
      adUnitId: _adUnitId,
      onAdLoaded: () {
        if (mounted) setState(() => _isLoaded = true);
      },
      onAdFailedToLoad: (_) {
        if (mounted) setState(() => _isLoaded = false);
      },
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showAds = ref.watch(showAdsProvider);

    if (!showAds || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: widget.size.width.toDouble(),
      height: widget.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
