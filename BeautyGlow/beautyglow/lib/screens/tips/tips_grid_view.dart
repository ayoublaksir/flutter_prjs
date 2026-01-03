import 'package:flutter/material.dart';
import '../../models/beauty_tip.dart';
import '../../core/responsive/responsive_util.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';

import 'tip_detail_screen.dart';

class TipsGridView extends StatefulWidget {
  final List<BeautyTip> tips;
  final String? selectedCategory;

  const TipsGridView({
    Key? key,
    required this.tips,
    this.selectedCategory,
  }) : super(key: key);

  @override
  State<TipsGridView> createState() => _TipsGridViewState();
}

class _TipsGridViewState extends State<TipsGridView> {
  final _responsive = ResponsiveUtil();

  @override
  Widget build(BuildContext context) {
    final filteredTips = widget.selectedCategory != null
        ? widget.tips
            .where((tip) => tip.category == widget.selectedCategory)
            .toList()
        : widget.tips;

    return GridView.builder(
      padding: EdgeInsets.all(_responsive.proportionateWidth(16)),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _responsive.getResponsiveGridCount(
          mobile: 1,
          tablet: 2,
          desktop: 3,
        ),
        childAspectRatio: 1.2,
        crossAxisSpacing: _responsive.proportionateWidth(16),
        mainAxisSpacing: _responsive.proportionateHeight(16),
      ),
      itemCount: filteredTips.length,
      itemBuilder: (context, index) {
        final tip = filteredTips[index];

        // Calculate the article index within its category
        final categoryTips =
            widget.tips.where((t) => t.category == tip.category).toList();
        final articleIndex = categoryTips.indexWhere((t) => t.id == tip.id);

        return _TipCard(
          tip: tip,
          articleIndex: articleIndex,
        );
      },
    );
  }
}

class _TipCard extends StatelessWidget {
  final BeautyTip tip;
  final int articleIndex;
  final _responsive = ResponsiveUtil();

  _TipCard({
    Key? key,
    required this.tip,
    required this.articleIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TipDetailScreen(tip: tip),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Hero Image
              Hero(
                tag: 'tip_image_${tip.title}',
                child: Image.asset(
                  tip.imagePath,
                  fit: BoxFit.cover,
                ),
              ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: EdgeInsets.all(_responsive.proportionateWidth(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Category Badge
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: _responsive.proportionateWidth(8),
                            vertical: _responsive.proportionateHeight(4),
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(tip.category)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tip.category.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _responsive.scaledFontSize(12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: _responsive.proportionateWidth(8)),
                        // Free indicator
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: _responsive.proportionateWidth(6),
                            vertical: _responsive.proportionateHeight(2),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'FREE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _responsive.scaledFontSize(10),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _responsive.proportionateHeight(8)),
                    // Title
                    Text(
                      tip.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _responsive.scaledFontSize(18),
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: _responsive.proportionateHeight(4)),
                    // Description
                    Text(
                      tip.shortDescription,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: _responsive.scaledFontSize(14),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
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
        return Color(0xFF9E9E9E); // Grey
    }
  }
}
