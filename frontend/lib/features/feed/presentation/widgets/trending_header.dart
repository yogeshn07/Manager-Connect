import 'package:flutter/material.dart';
import 'package:manager_connect/core/theme/app_colors.dart';

class TrendingHeader extends StatelessWidget {
  const TrendingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, size: 20, color: AppColors.accent),
          const SizedBox(width: 6),
          Text(
            'Trending in your org',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            'Recent',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
