import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/ads_service.dart';
import 'widgets/ads/banner_ad_widget.dart';

class TestAdApp extends StatelessWidget {
  const TestAdApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ad Test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Ad Test'),
        ),
        body: Column(
          children: [
            const Text('Testing Banner Ad Loading'),
            const SizedBox(height: 20),
            BannerAdWidget(
              margin: const EdgeInsets.all(16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final adService =
                    Provider.of<AdsService>(context, listen: false);
                adService.loadInterstitialAd();
              },
              child: const Text('Load Interstitial Ad'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                final adService =
                    Provider.of<AdsService>(context, listen: false);
                adService.loadRewardedAd();
              },
              child: const Text('Load Rewarded Ad'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final adService =
                    Provider.of<AdsService>(context, listen: false);
                final result = await adService.testBannerAdLoad();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Test result: ${result ? "Success" : "Failed"}'),
                  ),
                );
              },
              child: const Text('Test Banner Ad Load'),
            ),
          ],
        ),
      ),
    );
  }
}
