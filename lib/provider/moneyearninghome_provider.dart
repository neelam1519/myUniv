import 'package:flutter/material.dart'; // Corrected import for ChangeNotifier
import 'package:google_mobile_ads/google_mobile_ads.dart';

class MoneyEarningHomeProvider with ChangeNotifier {
  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isAdLoading = false;

  bool get isAdLoading => _isAdLoading;
  RewardedInterstitialAd? get rewardedInterstitialAd => _rewardedInterstitialAd;

  void loadAndShowRewardedInterstitialAd() {
    if (_isAdLoading) return;

    _isAdLoading = true;
    notifyListeners();

    RewardedInterstitialAd.load(
      adUnitId: 'ca-app-pub-7692584421652718/2009479725',
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          print('RewardedInterstitialAd loaded');
          _rewardedInterstitialAd = ad;
          _showRewardedInterstitialAd();
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('RewardedInterstitialAd failed to load: $error');
          _isAdLoading = false;
          notifyListeners();
        },
      ),
    );
  }

  void _showRewardedInterstitialAd() {
    if (_rewardedInterstitialAd == null) return;

    _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
        ad.dispose();
        print('RewardedInterstitialAd dismissed');
        _isAdLoading = false;
        notifyListeners();
      },
      onAdFailedToShowFullScreenContent: (RewardedInterstitialAd ad, AdError error) {
        ad.dispose();
        print('RewardedInterstitialAd failed to show: $error');
        _isAdLoading = false;
        notifyListeners();
      },
    );

    _rewardedInterstitialAd!.setImmersiveMode(true);
    _rewardedInterstitialAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      print('User earned reward: ${reward.amount} ${reward.type}');
    });

    _rewardedInterstitialAd = null;
  }

  @override
  void dispose() {
    _rewardedInterstitialAd?.dispose();
    super.dispose();
  }
}
