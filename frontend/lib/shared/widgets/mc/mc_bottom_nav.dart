import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';

/// Bottom Navigation — icon-only, no labels, 4px active dot.
/// Member: Home, Events, Challenges, Notifications, Profile.
/// Border-top only. No shadow.
class McBottomNav extends StatelessWidget {
  const McBottomNav({
    required this.currentIndex,
    required this.onTap,
    this.unreadNotifications = 0,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadNotifications;

  static const _icons = [
    Icons.home_outlined,
    Icons.calendar_today_outlined,
    Icons.emoji_events_outlined,
    Icons.notifications_outlined,
    Icons.person_outline,
  ];

  static const _activeIcons = [
    Icons.home,
    Icons.calendar_today,
    Icons.emoji_events,
    Icons.notifications,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: McColors.bgCard,
        border: Border(
          top: BorderSide(color: McColors.borderDefault, width: McSpacing.borderThin),
        ),
      ),
      padding: EdgeInsets.only(
        top: McSpacing.navPadTop,
        bottom: McSpacing.navPadBottom + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        children: List.generate(5, (i) => _tab(i)),
      ),
    );
  }

  Widget _tab(int index) {
    final active = index == currentIndex;
    final icon = active ? _activeIcons[index] : _icons[index];
    final color = active ? McColors.brand800 : McColors.textTertiary;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: McSpacing.navIconSize, color: color),
                if (index == 3 && unreadNotifications > 0)
                  Positioned(
                    top: -3,
                    right: -6,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: McColors.red400,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              width: McSpacing.navDotSize,
              height: McSpacing.navDotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? McColors.brand800 : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
