import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  final TextStyle? titleStyle;
  final TextStyle? actionStyle;
  final double titleFontSize;

  const SectionHeader({
    Key? key,
    required this.title,
    this.actionText,
    this.onAction,
    this.titleStyle,
    this.actionStyle,
    this.titleFontSize = 18,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: titleStyle ??
              TextStyle(
                fontSize: titleFontSize, 
                fontWeight: FontWeight.bold,
              ),
        ),
        if (actionText != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionText!,
              style: actionStyle,
            ),
          ),
      ],
    );
  }
}