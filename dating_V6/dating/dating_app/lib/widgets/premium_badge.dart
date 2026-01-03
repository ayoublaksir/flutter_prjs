import 'package:flutter/material.dart';

class PremiumBadge extends StatelessWidget {
  final VoidCallback? onTap;
  final bool mini;

  const PremiumBadge({Key? key, this.onTap, this.mini = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: mini ? 8.0 : 12.0,
          vertical: mini ? 4.0 : 6.0,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.pink],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(mini ? 12.0 : 16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.white, size: mini ? 14.0 : 18.0),
            SizedBox(width: 4.0),
            Text(
              'Premium',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: mini ? 10.0 : 14.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
