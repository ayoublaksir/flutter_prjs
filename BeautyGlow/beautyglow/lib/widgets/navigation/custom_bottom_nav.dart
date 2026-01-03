import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/navigation/nav_items.dart';
import '../../core/responsive/responsive_util.dart';

/// Custom bottom navigation bar with animations
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<NavItem> items;

  CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXLarge),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveUtil.instance.proportionateHeight(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items.asMap().entries.map((entry) {
              int index = entry.key;
              NavItem item = entry.value;
              bool isSelected = index == currentIndex;

              return _NavBarItem(
                item: item,
                isSelected: isSelected,
                onTap: () => onTap(index),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

/// Individual navigation bar item
class _NavBarItem extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  _NavBarItem({
    Key? key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtil.instance
                .proportionateWidth(AppDimensions.paddingSmall),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(
                  ResponsiveUtil.instance.proportionateWidth(
                    isSelected ? 6 : 4,
                  ),
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryPink.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected
                      ? AppColors.primaryPink
                      : AppColors.textSecondary,
                  size: ResponsiveUtil.instance.proportionateWidth(
                    AppDimensions.bottomNavIconSize,
                  ),
                ),
              )
                  .animate(
                    target: isSelected ? 1 : 0,
                  )
                  .scale(
                    duration: const Duration(milliseconds: 200),
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.1, 1.1),
                  ),
              SizedBox(
                height: ResponsiveUtil.instance.proportionateHeight(2),
              ),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: ResponsiveUtil.instance.scaledFontSize(10),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? AppColors.primaryPink
                      : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isSelected)
                Container(
                  margin: EdgeInsets.only(
                    top: ResponsiveUtil.instance.proportionateHeight(2),
                  ),
                  height: ResponsiveUtil.instance.proportionateHeight(2),
                  width: ResponsiveUtil.instance.proportionateWidth(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusCircular),
                  ),
                ).animate().scaleX(
                      duration: const Duration(milliseconds: 300),
                      begin: 0,
                      end: 1,
                      curve: Curves.easeOutBack,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
