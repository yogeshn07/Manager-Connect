import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_avatar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_spacing.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

/// Composer — post creation entry point.
/// White card, 14px radius, avatar + input pill + 4 action tiles.
class McComposer extends StatelessWidget {
  const McComposer({
    this.userInitials = 'Y',
    this.onTap,
    this.onRecognition,
    this.onPoll,
    this.onEvent,
    super.key,
  });

  final String userInitials;
  final VoidCallback? onTap;
  final VoidCallback? onRecognition;
  final VoidCallback? onPoll;
  final VoidCallback? onEvent;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        McSpacing.pageMargin, McSpacing.cardGap / 2,
        McSpacing.pageMargin, McSpacing.cardGap / 2,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: McColors.bgCard,
        borderRadius: BorderRadius.circular(McSpacing.radiusCard),
        border: Border.all(color: McColors.borderDefault, width: McSpacing.borderThin),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Row(
              children: [
                McAvatar(initials: userInitials, size: 36, backgroundColor: McColors.gray400),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: McColors.bgInput,
                      borderRadius: BorderRadius.circular(McSpacing.radiusInput),
                    ),
                    child: Text(
                      'Share something with your leaders...',
                      style: McTypography.body.copyWith(color: McColors.textTertiary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _action(Icons.campaign_outlined, 'Update', McColors.brand50, McColors.brand800, McColors.brand700, onTap),
              _action(Icons.emoji_events_outlined, 'Recognize', McColors.amber50, McColors.amber800, McColors.amber400, onRecognition),
              _action(Icons.poll_outlined, 'Poll', McColors.purple50, McColors.purple800, McColors.purple600, onPoll),
              _action(Icons.event_outlined, 'Event', McColors.coral50, McColors.coral800, McColors.coral600, onEvent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, Color tileBg, Color tileIcon, Color labelColor, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tileBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(child: Icon(icon, size: 16, color: tileIcon)),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: McTypography.pill.copyWith(
              color: labelColor,
              fontSize: 9,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
