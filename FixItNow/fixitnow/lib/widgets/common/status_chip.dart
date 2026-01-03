import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final Map<String, Color>? colorMap;
  final TextStyle? textStyle;
  final EdgeInsets? padding;

  const StatusChip({
    Key? key,
    required this.status,
    this.colorMap,
    this.textStyle,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultColorMap = {
      'pending': Colors.orange,
      'confirmed': Colors.blue,
      'completed': Colors.green,
      'cancelled': Colors.red,
      'in_progress': Colors.purple,
      'rejected': Colors.red.shade800,
    };

    final color = (colorMap ?? defaultColorMap)[status.toLowerCase()] ?? Colors.grey;
    
    return Chip(
      label: Text(
        _capitalize(status),
        style: textStyle ?? const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return '';
    return s.split('_').map((word) => '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
  }
}