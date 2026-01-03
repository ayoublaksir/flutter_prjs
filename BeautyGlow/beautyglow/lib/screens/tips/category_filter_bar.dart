import 'package:flutter/material.dart';
import '../../core/responsive/responsive_util.dart';

class CategoryFilterBar extends StatelessWidget {
  final String? selectedCategory;
  final Function(String?) onCategorySelected;

  const CategoryFilterBar({
    Key? key,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Skincare', 'Makeup', 'Haircare', 'Lifestyle'];

    return Container(
      height: ResponsiveUtil.instance.proportionateHeight(60),
      margin: EdgeInsets.symmetric(
        vertical: ResponsiveUtil.instance.proportionateHeight(16),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtil.instance.proportionateWidth(16),
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == 'All'
              ? selectedCategory == null
              : selectedCategory == category.toLowerCase();

          return Padding(
            padding: EdgeInsets.only(
              right: ResponsiveUtil.instance.proportionateWidth(12),
            ),
            child: _CategoryChip(
              label: category,
              isSelected: isSelected,
              onTap: () {
                onCategorySelected(
                  category == 'All' ? null : category.toLowerCase(),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtil.instance.proportionateWidth(20),
          vertical: ResponsiveUtil.instance.proportionateHeight(12),
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? _getCategoryColor(label)
              : _getCategoryColor(label).withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _getCategoryColor(label).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : _getCategoryColor(label),
            fontSize: ResponsiveUtil.instance.scaledFontSize(14),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'skincare':
        return Color(0xFFE91E63); // Pink
      case 'makeup':
        return Color(0xFF9C27B0); // Purple
      case 'haircare':
        return Color(0xFF3F51B5); // Indigo
      case 'lifestyle':
        return Color(0xFF009688); // Teal
      default:
        return Color(0xFF9E9E9E); // Grey for 'All' and unknown categories
    }
  }
}
