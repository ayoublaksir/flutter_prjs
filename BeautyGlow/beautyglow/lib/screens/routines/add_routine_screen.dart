import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../core/responsive/responsive_util.dart';
import '../../widgets/buttons/custom_button.dart';
import '../../models/routine.dart';
import '../../utils/validation_util.dart';
import '../../services/routine_service.dart';
import '../../services/ads_service.dart';

class AddRoutineScreen extends StatefulWidget {
  final Routine? routine;

  const AddRoutineScreen({Key? key, this.routine}) : super(key: key);

  @override
  State<AddRoutineScreen> createState() => _AddRoutineScreenState();
}

class _AddRoutineScreenState extends State<AddRoutineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<RoutineStep> _steps = [];
  String _selectedTimeOfDay = 'morning';
  bool _isActive = true;
  TimeOfDay? _reminderTime;
  bool _isReminderEnabled = true;

  @override
  void initState() {
    super.initState();
    if (widget.routine != null) {
      _nameController.text = widget.routine!.name;
      _descriptionController.text = widget.routine!.description ?? '';
      _selectedTimeOfDay = widget.routine!.timeOfDay;
      _isActive = widget.routine!.isActive;
      _reminderTime = widget.routine!.reminderTime;
      _isReminderEnabled = widget.routine!.isReminderEnabled;
      _steps.addAll(widget.routine!.steps);
    } else {
      // Set default reminder time based on time of day
      _reminderTime = _selectedTimeOfDay == 'morning'
          ? const TimeOfDay(hour: 7, minute: 0)
          : const TimeOfDay(hour: 21, minute: 0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addStep() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddStepBottomSheet(
        orderIndex: _steps.length,
        onAdd: (step) {
          if (mounted) {
            setState(() {
              _steps.add(step);
            });
          }
        },
      ),
    );
  }

  Future<void> _saveRoutine() async {
    if (_formKey.currentState!.validate() && _steps.isNotEmpty) {
      final routineService =
          Provider.of<RoutineService>(context, listen: false);
      final adsService = Provider.of<AdsService>(context, listen: false);

      try {
        if (widget.routine == null) {
          // Creating new routine - use our Firebase-integrated service
          await routineService.createRoutine(
            name: _nameController.text,
            timeOfDay: _selectedTimeOfDay,
            steps: _steps,
            reminderTime: _reminderTime,
            isReminderEnabled: _isReminderEnabled,
            description: _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '✅ Routine "${_nameController.text}" created successfully!'),
                backgroundColor: AppColors.successGreen,
                duration: const Duration(seconds: 2),
              ),
            );

            // Show success and navigate back
            Navigator.pop(context, true);

            // 🎯 STRATEGIC AD PLACEMENT: Show interstitial after routine creation
            // This is a high-value moment with engaged users
            await adsService.showInterstitialForRoutineCreation();
          }
        } else {
          // Updating existing routine
          final updatedRoutine = widget.routine!.copyWith(
            name: _nameController.text,
            description: _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text,
            timeOfDay: _selectedTimeOfDay,
            steps: _steps,
            isActive: _isActive,
            reminderTime: _reminderTime,
            isReminderEnabled: _isReminderEnabled,
          );

          await routineService.updateRoutine(updatedRoutine);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '✅ Routine "${_nameController.text}" updated successfully!'),
                backgroundColor: AppColors.successGreen,
                duration: const Duration(seconds: 2),
              ),
            );

            Navigator.pop(context, true);

            // Show routine save ad (less frequent than creation)
            await adsService.showInterstitialForRoutineSave();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error saving routine: $e'),
              backgroundColor: AppColors.errorRed,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else if (_steps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one step to your routine'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  /// Show time picker for reminder time
  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 7, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primaryPink,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  /// Format time for display
  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Not set';

    final hour = time.hour;
    final minute = time.minute;

    if (hour == 0) {
      return '12:${minute.toString().padLeft(2, '0')} AM';
    } else if (hour < 12) {
      return '$hour:${minute.toString().padLeft(2, '0')} AM';
    } else if (hour == 12) {
      return '12:${minute.toString().padLeft(2, '0')} PM';
    } else {
      return '${hour - 12}:${minute.toString().padLeft(2, '0')} PM';
    }
  }

  /// Update default reminder time when time of day changes
  void _onTimeOfDayChanged(String timeOfDay) {
    setState(() {
      _selectedTimeOfDay = timeOfDay;
      // Update default reminder time
      if (_reminderTime == null ||
          (_selectedTimeOfDay == 'morning' && _reminderTime!.hour > 12) ||
          (_selectedTimeOfDay == 'evening' && _reminderTime!.hour < 12)) {
        _reminderTime = _selectedTimeOfDay == 'morning'
            ? const TimeOfDay(hour: 7, minute: 0)
            : const TimeOfDay(hour: 21, minute: 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(widget.routine == null ? 'Create Routine' : 'Edit Routine'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(
            ResponsiveUtil.instance
                .proportionateWidth(AppDimensions.paddingMedium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Routine Name
              _buildSectionTitle('Routine Details'),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(12)),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Routine Name',
                  hintText: 'e.g., Morning Skincare',
                  prefixIcon:
                      const Icon(Icons.edit, color: AppColors.primaryPink),
                ),
                validator: (value) => ValidationUtil.validateRoutineName(value),
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Describe your routine...',
                  prefixIcon: const Icon(Icons.description,
                      color: AppColors.primaryPink),
                  alignLabelWithHint: true,
                ),
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(24)),

              // Time of Day
              _buildSectionTitle('When do you do this routine?'),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(12)),
              Row(
                children: [
                  _buildTimeChip('morning', 'Morning', Icons.wb_sunny),
                  SizedBox(
                      width: ResponsiveUtil.instance.proportionateWidth(12)),
                  _buildTimeChip('evening', 'Evening', Icons.nightlight_round),
                ],
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(24)),

              // Active Status
              Container(
                padding: EdgeInsets.all(
                  ResponsiveUtil.instance
                      .proportionateWidth(AppDimensions.paddingMedium),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColorLight,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Routine',
                          style: AppTypography.labelLarge,
                        ),
                        Text(
                          'Show in daily routines',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (value) {
                        if (mounted) {
                          setState(() {
                            _isActive = value;
                          });
                        }
                      },
                      activeColor: AppColors.primaryPink,
                    ),
                  ],
                ),
              ).animate().fadeIn().slideX(begin: 0.1, end: 0),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(24)),

              // 🔔 NOTIFICATION SETTINGS - NEW FEATURE
              _buildSectionTitle('Daily Reminder'),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(12)),
              Container(
                padding: EdgeInsets.all(
                  ResponsiveUtil.instance
                      .proportionateWidth(AppDimensions.paddingMedium),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColorLight,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Reminder Enable/Disable
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enable Reminders',
                              style: AppTypography.labelLarge,
                            ),
                            Text(
                              'Get notified to do your routine',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isReminderEnabled,
                          onChanged: (value) {
                            if (mounted) {
                              setState(() {
                                _isReminderEnabled = value;
                              });
                            }
                          },
                          activeColor: AppColors.primaryPink,
                        ),
                      ],
                    ),

                    // Reminder Time Picker (only shown if enabled)
                    if (_isReminderEnabled) ...[
                      SizedBox(
                          height:
                              ResponsiveUtil.instance.proportionateHeight(16)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reminder Time',
                                style: AppTypography.labelMedium,
                              ),
                              Text(
                                _formatTime(_reminderTime),
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.primaryPink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _selectReminderTime,
                            icon: const Icon(Icons.access_time, size: 18),
                            label: const Text('Change'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.primaryPink.withOpacity(0.1),
                              foregroundColor: AppColors.primaryPink,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1, end: 0),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(24)),

              // Steps Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Routine Steps'),
                  TextButton.icon(
                    onPressed: _addStep,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Add Step'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryPink,
                    ),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(12)),

              if (_steps.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(
                    ResponsiveUtil.instance
                        .proportionateWidth(AppDimensions.paddingLarge),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.softRose,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(
                      color: AppColors.primaryPink.withOpacity(0.3),
                      style: BorderStyle.solid,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.playlist_add,
                        size: 48,
                        color: AppColors.primaryPink.withOpacity(0.5),
                      ),
                      SizedBox(
                          height:
                              ResponsiveUtil.instance.proportionateHeight(8)),
                      Text(
                        'No steps added yet',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Tap "Add Step" to build your routine',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _steps.length,
                  onReorder: (oldIndex, newIndex) {
                    if (mounted) {
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        final step = _steps.removeAt(oldIndex);
                        _steps.insert(newIndex, step);
                      });
                    }
                  },
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return _StepCard(
                      key: ValueKey(step.id),
                      step: step,
                      index: index,
                      onDelete: () {
                        if (mounted) {
                          setState(() {
                            _steps.removeAt(index);
                          });
                        }
                      },
                      onEdit: () {
                        // TODO: Implement edit step
                      },
                    );
                  },
                ),
              ],

              SizedBox(height: ResponsiveUtil.instance.proportionateHeight(80)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveRoutine,
        backgroundColor: AppColors.primaryPink,
        label: Text(
          widget.routine == null ? 'Create Routine' : 'Update Routine',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.save, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.labelLarge.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTimeChip(String value, String label, IconData icon) {
    final isSelected = _selectedTimeOfDay == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (mounted) {
            _onTimeOfDayChanged(value);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(
            ResponsiveUtil.instance
                .proportionateWidth(AppDimensions.paddingMedium),
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryPink : Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: isSelected ? AppColors.primaryPink : AppColors.dividerGray,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryPink.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primaryPink,
                size: 24,
              ),
              SizedBox(width: ResponsiveUtil.instance.proportionateWidth(8)),
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final RoutineStep step;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _StepCard({
    Key? key,
    required this.step,
    required this.index,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        bottom: ResponsiveUtil.instance.proportionateHeight(8),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        elevation: 2,
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primaryPink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          title: Text(
            step.name,
            style: AppTypography.labelLarge,
          ),
          subtitle: Text(
            '${step.duration} minutes',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppColors.errorRed,
                onPressed: onDelete,
              ),
              const Icon(
                Icons.drag_handle,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }
}

class _AddStepBottomSheet extends StatefulWidget {
  final int orderIndex;
  final Function(RoutineStep) onAdd;

  const _AddStepBottomSheet(
      {Key? key, required this.orderIndex, required this.onAdd})
      : super(key: key);

  @override
  State<_AddStepBottomSheet> createState() => _AddStepBottomSheetState();
}

class _AddStepBottomSheetState extends State<_AddStepBottomSheet> {
  final _nameController = TextEditingController();
  final _productController = TextEditingController();
  int _duration = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _productController.dispose();
    super.dispose();
  }

  void _addStep() {
    if (_nameController.text.isNotEmpty) {
      final step = RoutineStep(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        productName:
            _productController.text.isEmpty ? null : _productController.text,
        durationMinutes: _duration,
        orderIndex: widget.orderIndex,
      );
      widget.onAdd(step);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXLarge),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtil.instance
              .proportionateWidth(AppDimensions.paddingLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.dividerGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),
            Text(
              'Add Step',
              style: AppTypography.headingSmall,
            ),
            SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Step Name',
                hintText: 'e.g., Apply moisturizer',
                prefixIcon: Icon(Icons.check_circle_outline,
                    color: AppColors.primaryPink),
              ),
              autofocus: true,
            ),
            SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),
            TextField(
              controller: _productController,
              decoration: const InputDecoration(
                labelText: 'Product (Optional)',
                hintText: 'e.g., CeraVe Daily Moisturizer',
                prefixIcon: Icon(Icons.shopping_bag_outlined,
                    color: AppColors.primaryPink),
              ),
            ),
            SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),
            Text(
              'Duration: $_duration minute${_duration > 1 ? 's' : ''}',
              style: AppTypography.labelLarge,
            ),
            Slider(
              value: _duration.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              activeColor: AppColors.primaryPink,
              inactiveColor: AppColors.softRose,
              label: '$_duration min',
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _duration = value.round();
                  });
                }
              },
            ),
            SizedBox(height: ResponsiveUtil.instance.proportionateHeight(24)),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Cancel',
                    type: ButtonType.outline,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SizedBox(width: ResponsiveUtil.instance.proportionateWidth(12)),
                Expanded(
                  child: CustomButton(
                    text: 'Add Step',
                    onPressed: _addStep,
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtil.instance.proportionateHeight(16)),
          ],
        ),
      ),
    );
  }
}
