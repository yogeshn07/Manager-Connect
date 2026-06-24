import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

/// Top Bar Type A — Logo + title + actions.
/// Height: auto, bg white, border-bottom 0.5px.
/// Logo gem: 33px, 9px radius, brand-800 bg, white icon 16px.
class McTopBarA extends StatelessWidget implements PreferredSizeWidget {
  const McTopBarA({
    this.actions = const [],
    this.notificationCount = 0,
    super.key,
  });

  final List<Widget> actions;
  final int notificationCount;

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 11),
        decoration: BoxDecoration(
          color: McColors.bgCard,
          border: Border(
            bottom: BorderSide(color: McColors.borderDefault, width: McSpacing.borderThin),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 33,
              height: 33,
              decoration: BoxDecoration(
                color: McColors.brand800,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(
                child: Icon(Icons.hub, size: 16, color: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manager Connect',
                    style: McTypography.h3.copyWith(color: McColors.textPrimary),
                  ),
                  Text(
                    'Leadership community',
                    style: McTypography.caption.copyWith(color: McColors.textTertiary),
                  ),
                ],
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}

/// Top Bar Type B — Back link + title.
/// Back: 13px/500 brand-700, arrow + parent name.
class McTopBarB extends StatelessWidget implements PreferredSizeWidget {
  const McTopBarB({
    required this.title,
    this.backLabel,
    this.onBack,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String? backLabel;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        decoration: BoxDecoration(
          color: McColors.bgCard,
          border: Border(
            bottom: BorderSide(color: McColors.borderDefault, width: McSpacing.borderThin),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios, size: 17, color: McColors.textLink),
                  if (backLabel != null) ...[
                    const SizedBox(width: 2),
                    Text(
                      backLabel!,
                      style: McTypography.h4.copyWith(color: McColors.textLink),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: McTypography.h3.copyWith(color: McColors.textPrimary),
              ),
            ),
            ...actions,
          ],
        ),
      ),
    );
  }
}
