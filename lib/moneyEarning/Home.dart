// import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
//
// class MoneyEarningHome extends StatefulWidget {
//   const MoneyEarningHome({super.key});
//
//   @override
//   _MoneyEarningHomeState createState() => _MoneyEarningHomeState();
// }
//
// class _MoneyEarningHomeState extends State<MoneyEarningHome> {
//   RewardedInterstitialAd? _rewardedInterstitialAd;
//   bool _isAdLoading = false;
//
//   @override
//   void initState() {
//     super.initState();
//     MobileAds.instance.initialize();
//   }
//
//   void _loadAndShowRewardedInterstitialAd() {
//     if (_isAdLoading) return;
//
//     setState(() {
//       _isAdLoading = true;
//     });
//
//     RewardedInterstitialAd.load(
//       adUnitId: 'ca-app-pub-7692584421652718/2009479725',
//       request: const AdRequest(),
//       rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
//         onAdLoaded: (RewardedInterstitialAd ad) {
//           print('RewardedInterstitialAd loaded');
//           _rewardedInterstitialAd = ad;
//           _showRewardedInterstitialAd();
//         },
//         onAdFailedToLoad: (LoadAdError error) {
//           print('RewardedInterstitialAd failed to load: $error');
//           setState(() {
//             _isAdLoading = false;
//           });
//         },
//       ),
//     );
//   }
//
//   void _showRewardedInterstitialAd() {
//     if (_rewardedInterstitialAd == null) return;
//
//     _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
//       onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
//         ad.dispose();
//         print('RewardedInterstitialAd dismissed');
//         setState(() {
//           _isAdLoading = false;
//         });
//       },
//       onAdFailedToShowFullScreenContent: (RewardedInterstitialAd ad, AdError error) {
//         ad.dispose();
//         print('RewardedInterstitialAd failed to show: $error');
//         setState(() {
//           _isAdLoading = false;
//         });
//       },
//     );
//
//     _rewardedInterstitialAd!.setImmersiveMode(true);
//     _rewardedInterstitialAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
//       print('User earned reward: ${reward.amount} ${reward.type}');
//       // Add logic here to reward the user with 1 coin
//     });
//
//     _rewardedInterstitialAd = null;
//   }
//
//   @override
//   void dispose() {
//     _rewardedInterstitialAd?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Money Earning App'),
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: <Widget>[
//               const Text(
//                 'Welcome to Money Earning App!',
//                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _loadAndShowRewardedInterstitialAd,
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                   textStyle: const TextStyle(fontSize: 18),
//                 ), // Load and show the ad on button click
//                 child: const Text('Start Earning'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../provider/moneyearninghome_provider.dart';

class MoneyEarningHome extends StatefulWidget {
  const MoneyEarningHome({super.key});

  @override
  State<MoneyEarningHome> createState() => _MoneyEarningHomeState();
}

class _MoneyEarningHomeState extends State<MoneyEarningHome> {
  @override
  void initState() {
    MobileAds.instance.initialize();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Earning App'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Welcome to Money Earning App!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Provider.of<MoneyEarningHomeProvider>(context, listen: false).loadAndShowRewardedInterstitialAd();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Start Earning'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
