import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/responsive/responsive_util.dart';
import '../../widgets/buttons/custom_button.dart';
import '../../models/routine.dart';
import '../../services/ads_service.dart';
import '../../services/routine_service.dart';

class ExecuteRoutineScreen extends StatefulWidget {
  final Routine routine;

  const ExecuteRoutineScreen({Key? key, required this.routine})
      : super(key: key);

  @override
  State<ExecuteRoutineScreen> createState() => _ExecuteRoutineScreenState();
}

class _ExecuteRoutineScreenState extends State<ExecuteRoutineScreen>
    with TickerProviderStateMixin {
  final List<String> _completedSteps = [];
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  double get _progress {
    if (widget.routine.steps.isEmpty) return 0;
    return _completedSteps.length / widget.routine.steps.length;
  }

  void _toggleStep(String stepId) {
    setState(() {
      if (_completedSteps.contains(stepId)) {
        _completedSteps.remove(stepId);
      } else {
        _completedSteps.add(stepId);
      }
    });
    _progressController.forward(from: 0);

    // Check if all steps are completed
    if (_completedSteps.length == widget.routine.steps.length) {
      _showCompletionDialog();
    }
  }

  Future<void> _completeRoutine() async {
    final routineService = Provider.of<RoutineService>(context, listen: false);
    final adsService = Provider.of<AdsService>(context, listen: false);

    try {
      // ✅ USE NEW FIREBASE-INTEGRATED ROUTINE SERVICE
      await routineService.completeRoutine(widget.routine.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 "${widget.routine.name}" completed!'),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pop(context, true);

        // 🎯 STRATEGIC AD PLACEMENT: Show interstitial after routine completion
        // This is a high-engagement moment - user just finished a routine
        await adsService.showInterstitialForRoutineCompletion();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error completing routine: $e'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXLarge),
        ),
        child: Container(
          padding: EdgeInsets.all(
            ResponsiveUtil.instance
                .proportionateWidth(AppDimensions.paddingLarge),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 48,
                  color: AppColors.successGreen,
                ),
              ).animate().scale(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                  ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),
              Text(
                'Routine Complete! 🎉',
                style: AppTypography.headingMedium,
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(8)),
              Text(
                'Great job completing your ${widget.routine.name}',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(24)),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'View Progress',
                      type: ButtonType.outline,
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context, true);
                      },
                    ),
                  ),
                  SizedBox(
                      width: ResponsiveUtil.instance.proportionateWidth(12)),
                  Expanded(
                    child: CustomButton(
                      text: 'Done',
                      onPressed: () {
                        Navigator.pop(context);
                        _completeRoutine();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar with Progress
            _buildCustomAppBar(),

            // Steps List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(
                  ResponsiveUtil.instance
                      .proportionateWidth(AppDimensions.paddingMedium),
                ),
                itemCount: widget.routine.steps.length,
                itemBuilder: (context, index) {
                  final step = widget.routine.steps[index];
                  final isCompleted = _completedSteps.contains(step.id);

                  return _StepChecklistItem(
                    step: step,
                    index: index,
                    isCompleted: isCompleted,
                    onToggle: () => _toggleStep(step.id),
                  )
                      .animate()
                      .fadeIn(
                        delay: Duration(milliseconds: 100 * index),
                        duration: const Duration(milliseconds: 300),
                      )
                      .slideY(begin: 0.1, end: 0);
                },
              ),
            ),

            // Bottom Action Bar
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveUtil.instance.proportionateWidth(AppDimensions.paddingMedium),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                iconSize: 24,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.routine.name,
                      style: AppTypography.headingSmall,
                    ),
                    Text(
                      '${widget.routine.steps.length} steps • ${widget.routine.formattedDuration}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return CircularPercentIndicator(
                    radius: 30.0,
                    lineWidth: 4.0,
                    percent: _progress,
                    center: Text(
                      '${(_progress * 100).toInt()}%',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryPink,
                      ),
                    ),
                    progressColor: AppColors.primaryPink,
                    backgroundColor: AppColors.softRose,
                    circularStrokeCap: CircularStrokeCap.round,
                  );
                },
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtil.instance.proportionateHeight(8)),
          // Progress Bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.dividerGray,
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final isAllCompleted =
        _completedSteps.length == widget.routine.steps.length;

    return Container(
      padding: EdgeInsets.all(
        ResponsiveUtil.instance.proportionateWidth(AppDimensions.paddingMedium),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColorLight,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: CustomButton(
          text: isAllCompleted ? 'Complete Routine' : 'Mark All as Done',
          onPressed: isAllCompleted
              ? _completeRoutine
              : () {
                  setState(() {
                    _completedSteps.clear();
                    _completedSteps
                        .addAll(widget.routine.steps.map((s) => s.id));
                  });
                  _progressController.forward(from: 0);
                  _showCompletionDialog();
                },
          isFullWidth: true,
          gradient: isAllCompleted ? AppColors.primaryGradient : null,
          color: isAllCompleted ? null : AppColors.softRose,
          textColor: isAllCompleted ? Colors.white : AppColors.primaryPink,
        ),
      ),
    );
  }
}

class _StepChecklistItem extends StatelessWidget {
  final RoutineStep step;
  final int index;
  final bool isCompleted;
  final VoidCallback onToggle;

  const _StepChecklistItem({
    Key? key,
    required this.step,
    required this.index,
    required this.isCompleted,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveUtil.instance.proportionateHeight(12),
      ),
      child: Material(
        color: isCompleted
            ? AppColors.successGreen.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        elevation: isCompleted ? 0 : 2,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          child: Container(
            padding: EdgeInsets.all(
              ResponsiveUtil.instance
                  .proportionateWidth(AppDimensions.paddingMedium),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              border: Border.all(
                color: isCompleted
                    ? AppColors.successGreen.withOpacity(0.3)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.successGreen : Colors.white,
                    border: Border.all(
                      color: isCompleted
                          ? AppColors.successGreen
                          : AppColors.dividerGray,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ).animate().scale(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.elasticOut,
                          )
                      : null,
                ),
                SizedBox(width: ResponsiveUtil.instance.proportionateWidth(16)),

                // Step Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.name,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                          color: isCompleted
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (step.productName != null) ...[
                        SizedBox(
                            height:
                                ResponsiveUtil.instance.proportionateHeight(4)),
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(
                                width: ResponsiveUtil.instance
                                    .proportionateWidth(4)),
                            Expanded(
                              child: Text(
                                step.productName!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Duration
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtil.instance.proportionateWidth(8),
                    vertical: ResponsiveUtil.instance.proportionateHeight(4),
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.successGreen.withOpacity(0.1)
                        : AppColors.softRose,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${step.duration} min',
                    style: AppTypography.caption.copyWith(
                      color: isCompleted
                          ? AppColors.successGreen
                          : AppColors.primaryPink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
