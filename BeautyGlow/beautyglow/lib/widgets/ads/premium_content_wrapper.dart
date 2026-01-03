import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/responsive/responsive_util.dart';
import 'rewarded_ad_dialog.dart';

/// Wrapper widget for premium content that requires watching ads to unlock
class PremiumContentWrapper extends StatefulWidget {
  final Widget child;
  final String title;
  final String message;
  final String rewardDescription;
  final bool isUnlocked;
  final VoidCallback? onUnlocked;
  final Widget? lockedWidget;

  const PremiumContentWrapper({
    Key? key,
    required this.child,
    required this.title,
    required this.message,
    required this.rewardDescription,
    required this.isUnlocked,
    this.onUnlocked,
    this.lockedWidget,
  }) : super(key: key);

  @override
  State<PremiumContentWrapper> createState() => _PremiumContentWrapperState();
}

class _PremiumContentWrapperState extends State<PremiumContentWrapper> {
  @override
  Widget build(BuildContext context) {
    if (widget.isUnlocked) {
      return widget.child;
    }

    return widget.lockedWidget ?? _buildLockedContent();
  }

  Widget _buildLockedContent() {
    return Container(
      margin: EdgeInsets.all(ResponsiveUtil.instance.proportionateWidth(8)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Blurred content preview
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.grey.withOpacity(0.3),
                BlendMode.saturation,
              ),
              child: widget.child,
            ),
          ),

          // Overlay with lock icon and unlock button
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lock icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPink.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  SizedBox(
                      height: ResponsiveUtil.instance.proportionateHeight(16)),

                  // Unlock text
                  Text(
                    'Premium Content',
                    style: TextStyle(
                      fontSize: ResponsiveUtil.instance.scaledFontSize(18),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                      height: ResponsiveUtil.instance.proportionateHeight(8)),

                  Text(
                    'Watch an ad to unlock',
                    style: TextStyle(
                      fontSize: ResponsiveUtil.instance.scaledFontSize(14),
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  SizedBox(
                      height: ResponsiveUtil.instance.proportionateHeight(16)),

                  // Unlock button
                  ElevatedButton.icon(
                    onPressed: _showRewardedAdDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            ResponsiveUtil.instance.proportionateWidth(16),
                        vertical:
                            ResponsiveUtil.instance.proportionateHeight(8),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: Text(
                      'Unlock',
                      style: TextStyle(
                        fontSize: ResponsiveUtil.instance.scaledFontSize(14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRewardedAdDialog() {
    showDialog(
      context: context,
      builder: (context) => RewardedAdDialog(
        title: widget.title,
        message: widget.message,
        rewardDescription: widget.rewardDescription,
        onRewarded: () {
          widget.onUnlocked?.call();
        },
      ),
    );
  }
}
