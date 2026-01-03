import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ads_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_util.dart';

/// Dialog for showing rewarded ads to unlock premium content
class RewardedAdDialog extends StatefulWidget {
  final String title;
  final String message;
  final String rewardDescription;
  final VoidCallback onRewarded;
  final VoidCallback? onCancel;

  const RewardedAdDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.rewardDescription,
    required this.onRewarded,
    this.onCancel,
  }) : super(key: key);

  @override
  State<RewardedAdDialog> createState() => _RewardedAdDialogState();
}

class _RewardedAdDialogState extends State<RewardedAdDialog> {
  bool _isLoading = false;
  bool _isAdReady = false;

  @override
  void initState() {
    super.initState();
    _checkAdReady();
  }

  void _checkAdReady() {
    final adService = Provider.of<AdsService>(context, listen: false);
    if (mounted) {
      setState(() {
        _isAdReady = adService.isRewardedAdReady;
      });
    }
  }

  Future<void> _showRewardedAd() async {
    if (!_isAdReady) {
      // Try to load the ad first
      final adService = Provider.of<AdsService>(context, listen: false);
      await adService.loadRewardedAd();
      _checkAdReady();

      if (!_isAdReady) {
        _showErrorDialog();
        return;
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final adService = Provider.of<AdsService>(context, listen: false);
    final success = await adService.showRewardedAd(
      featureType: 'rewarded',
      onRewardEarned: () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // Return true to indicate successful reward
          Navigator.of(context).pop(true);
        }
      },
      onAdFailedToShow: () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showErrorDialog();
        }
      },
    );

    if (!success && mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ad Not Available'),
        content: const Text(
          'The reward ad is not available right now. Please try again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(ResponsiveUtil.instance.proportionateWidth(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.card_giftcard,
                color: AppColors.primaryPink,
                size: 30,
              ),
            ),
            SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),

            // Title
            Text(
              widget.title,
              style: TextStyle(
                fontSize: ResponsiveUtil.instance.scaledFontSize(20),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtil.instance.proportionateHeight(8)),

            // Message
            Text(
              widget.message,
              style: TextStyle(
                fontSize: ResponsiveUtil.instance.scaledFontSize(14),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),

            // Reward description
            Container(
              padding: EdgeInsets.all(
                  ResponsiveUtil.instance.proportionateWidth(12)),
              decoration: BoxDecoration(
                color: AppColors.primaryPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryPink.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: AppColors.primaryPink,
                    size: 20,
                  ),
                  SizedBox(
                      width: ResponsiveUtil.instance.proportionateWidth(8)),
                  Expanded(
                    child: Text(
                      widget.rewardDescription,
                      style: TextStyle(
                        fontSize: ResponsiveUtil.instance.scaledFontSize(14),
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveUtil.instance.proportionateHeight(24)),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            widget.onCancel?.call();
                          },
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: ResponsiveUtil.instance.scaledFontSize(14),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtil.instance.proportionateWidth(12)),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _showRewardedAd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Watch Ad',
                            style: TextStyle(
                              fontSize:
                                  ResponsiveUtil.instance.scaledFontSize(14),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
