import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;

class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showProfileIcon;
  final bool showNotifications;
  final int notificationCount;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? textColor;
  final bool centerTitle;
  final double elevation;
  final Widget? leading;
  final Widget? flexibleSpace;

  const ModernAppBar({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.showProfileIcon = false,
    this.showNotifications = false,
    this.notificationCount = 0,
    this.onProfileTap,
    this.onNotificationTap,
    this.actions,
    this.backgroundColor,
    this.textColor,
    this.centerTitle = true,
    this.elevation = 0,
    this.leading,
    this.flexibleSpace,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBackgroundColor = backgroundColor ?? theme.colorScheme.surface;
    final defaultTextColor = textColor ?? theme.colorScheme.onSurface;

    return AppBar(
      backgroundColor: defaultBackgroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      leading:
          leading ??
          (showBackButton && Navigator.canPop(context)
              ? IconButton(
                icon: Icon(Icons.arrow_back, color: defaultTextColor),
                onPressed: () => Navigator.pop(context),
              )
              : null),
      title: Text(
        title,
        style: TextStyle(
          color: defaultTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: actions ?? _buildDefaultActions(context, defaultTextColor),
      flexibleSpace: flexibleSpace,
    );
  }

  List<Widget> _buildDefaultActions(BuildContext context, Color iconColor) {
    final actionsList = <Widget>[];

    if (showNotifications) {
      actionsList.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: IconButton(
            icon:
                notificationCount > 0
                    ? badges.Badge(
                      badgeContent: Text(
                        notificationCount.toString(),
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      badgeStyle: badges.BadgeStyle(
                        badgeColor: Theme.of(context).colorScheme.primary,
                        padding: EdgeInsets.all(5),
                      ),
                      child: Icon(
                        Icons.notifications_outlined,
                        color: iconColor,
                      ),
                    )
                    : Icon(Icons.notifications_outlined, color: iconColor),
            onPressed:
                onNotificationTap ??
                () {
                  // Default notification action
                  Navigator.pushNamed(context, '/notifications');
                },
          ),
        ),
      );
    }

    if (showProfileIcon) {
      actionsList.add(
        Padding(
          padding: const EdgeInsets.only(right: 16.0, left: 8.0),
          child: GestureDetector(
            onTap:
                onProfileTap ??
                () {
                  // Default profile action
                  Navigator.pushNamed(context, '/profile');
                },
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.2),
              child: Icon(
                Icons.person,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      );
    }

    return actionsList;
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
