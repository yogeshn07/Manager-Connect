import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

/// Moonchild bottom navigation — 72px, white, 1px top border.
/// Active pill: 48×28 lime (#C5FF55), dark text.
/// Inactive: muted gray icon + label.
class MCBottomNav extends StatelessWidget {
  const MCBottomNav({
    required this.currentIndex,
    required this.onTap,
    this.unreadAlerts = false,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool unreadAlerts;

  static const _items = [
    (icon: Icons.home_outlined,          active: Icons.home,          label: 'Home'),
    (icon: Icons.explore_outlined,       active: Icons.explore,       label: 'Explore'),
    (icon: Icons.emoji_events_outlined,  active: Icons.emoji_events,  label: 'Challenges'),
    (icon: Icons.assessment,             active: Icons.assessment,    label: 'Analytics'),
    (icon: Icons.person_outline,         active: Icons.person,        label: 'Profile'),
    (icon: Icons.electric_bolt_outlined, active: Icons.electric_bolt, label: 'Insights'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: MCColors.card,
        border: Border(top: BorderSide(color: MCColors.borderLight)),
      ),
      padding: EdgeInsets.only(
        top: 8,
        bottom: bottomPad + 8,
        left: 4,
        right: 4,
      ),
      child: Row(
        children: List.generate(_items.length, _tab),
      ),
    );
  }

  Widget _tab(int i) {
    final active = i == currentIndex;
    final item   = _items[i];

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(i),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width:  MCSpacing.navPillW,
                  height: MCSpacing.navPillH,
                  decoration: BoxDecoration(
                    color: active ? MCColors.energyRed : Colors.transparent,
                    borderRadius: BorderRadius.circular(MCSpacing.navPillRadius),
                  ),
                  child: Center(
                    child: Icon(
                      active ? item.active : item.icon,
                      size: MCSpacing.navIconSize,
                      color: active
                          ? Colors.white
                          : MCColors.textMuted,
                    ),
                  ),
                ),
                // Alert dot on Recognize tab (index 2)
                if (i == 2 && unreadAlerts)
                  const Positioned(
                    top: 3,
                    right: 6,
                    child: SizedBox(
                      width: 7,
                      height: 7,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: MCColors.energyRed,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: active
                  ? MCTypography.navActive.copyWith(color: MCColors.energyRed)
                  : MCTypography.navInactive,
              child: Text(item.label, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
