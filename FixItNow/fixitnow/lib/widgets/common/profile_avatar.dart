import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData placeholder;
  final double iconSize;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const ProfileAvatar({
    Key? key,
    this.imageUrl,
    this.radius = 40,
    this.placeholder = Icons.person,
    this.iconSize = 30,
    this.backgroundColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor.withOpacity(0.1),
        backgroundImage:
            imageUrl != null && imageUrl!.isNotEmpty ? NetworkImage(imageUrl!) : null,
        child: imageUrl == null || imageUrl!.isEmpty
            ? Icon(placeholder, size: iconSize, color: Theme.of(context).primaryColor)
            : null,
      ),
    );
  }
}