import 'package:flutter/material.dart';
import 'package:manager_connect/core/theme/app_colors.dart';

class ComposerCard extends StatelessWidget {
  const ComposerCard({
    this.onTap,
    this.onRecognitionTap,
    this.onPollTap,
    this.onEventTap,
    super.key,
  });

  final VoidCallback? onTap;
  final VoidCallback? onRecognitionTap;
  final VoidCallback? onPollTap;
  final VoidCallback? onEventTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Center(
                        child: Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Share something with your leaders...',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _quickAction(Icons.article_outlined, 'Share Update', AppColors.brandPrimary, onTap),
                _quickAction(Icons.emoji_events_outlined, 'Recognition', AppColors.accent, onRecognitionTap),
                _quickAction(Icons.poll_outlined, 'Poll', AppColors.connectBuddyBadge, onPollTap),
                _quickAction(Icons.event_outlined, 'Event', AppColors.successGreen, onEventTap),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
