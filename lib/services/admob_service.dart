import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  AdMobService._internal();

  static final AdMobService instance = AdMobService._internal();

  static const String _bannerAdUnitId =
      'ca-app-pub-3387480177023669/2691090902';

  BannerAd? _bannerAd;

  final ValueNotifier<bool> bannerAdLoaded = ValueNotifier<bool>(false);

  void loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          bannerAdLoaded.value = true;
        },
        onAdFailedToLoad: (ad, error) {
          bannerAdLoaded.value = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd!.load();
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    bannerAdLoaded.value = false;
  }

  Widget buildBannerAdWidget() {
    return ValueListenableBuilder<bool>(
      valueListenable: bannerAdLoaded,
      builder: (context, loaded, _) {
        if (!loaded || _bannerAd == null) {
          return const SizedBox(height: 0, width: double.infinity);
        }

        return Container(
          alignment: Alignment.center,
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        );
      },
    );
  }
}
