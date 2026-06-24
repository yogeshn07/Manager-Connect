import 'package:flutter/material.dart';
import 'package:manager_connect/shared/widgets/mc/mc_avatar.dart';
import 'package:manager_connect/shared/widgets/mc/mc_colors.dart';
import 'package:manager_connect/shared/widgets/mc/mc_typography.dart';

/// Social Proof Row — "Name, Name and N others [verb]".
/// Stacked avatars (max 4, 20px, -4px overlap) + text.
/// Container: bg #F4F5F7, 10px radius, 9-10px padding.
class McSocialProofRow extends StatelessWidget {
  const McSocialProofRow({
    required this.names,
    required this.totalCount,
    required this.verb,
    required this.avatarInitials,
    required this.avatarColors,
    super.key,
  });

  final List<String> names;
  final int totalCount;
  final String verb;
  final List<String> avatarInitials;
  final List<Color> avatarColors;

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) return const SizedBox.shrink();

    final displayNames = names.take(2).toList();
    final othersCount = totalCount - displayNames.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: McColors.bgInput,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          McAvatar.stack(
            initialsList: avatarInitials.take(4).toList(),
            colors: avatarColors.take(4).toList(),
            size: 20,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: McTypography.bodySm.copyWith(color: McColors.textTertiary),
                children: [
                  if (displayNames.isNotEmpty)
                    TextSpan(
                      text: displayNames.first,
                      style: McTypography.bodySm.copyWith(
                        fontWeight: FontWeight.w500,
                        color: McColors.textPrimary,
                      ),
                    ),
                  if (displayNames.length > 1) ...[
                    const TextSpan(text: ', '),
                    TextSpan(
                      text: displayNames[1],
                      style: McTypography.bodySm.copyWith(
                        fontWeight: FontWeight.w500,
                        color: McColors.textPrimary,
                      ),
                    ),
                  ],
                  if (othersCount > 0)
                    TextSpan(text: ' and $othersCount others '),
                  TextSpan(text: verb),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
