import 'package:flutter/material.dart';

class RatingDisplay extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final double iconSize;
  final Color? iconColor;
  final TextStyle? textStyle;

  const RatingDisplay({
    Key? key,
    required this.rating,
    required this.reviewCount,
    this.iconSize = 16,
    this.iconColor,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: iconSize,
          color: iconColor ?? Colors.amber,
        ),
        const SizedBox(width: 4),
        Text(
          '$rating (${reviewCount > 0 ? '$reviewCount reviews' : 'No reviews yet'})',
          style: textStyle ?? TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }
}