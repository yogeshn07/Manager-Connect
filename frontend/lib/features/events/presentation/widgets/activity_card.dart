import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manager_connect/features/events/data/models/activity_dto.dart';

String _toTitleCase(String raw) => raw
    .replaceAll('_', ' ')
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

class ActivityCard extends StatelessWidget {
  const ActivityCard({required this.activity, this.onTap, super.key});

  final ActivityDto activity;
  final VoidCallback? onTap;

  static const _categoryIcons = {
    'games': Icons.sports_cricket,
    'outings': Icons.hiking,
    'social_connect': Icons.coffee,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _categoryIcons[activity.eventCategory] ?? Icons.event,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      activity.title,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (activity.isCancelled)
                    Chip(
                      label: const Text('Cancelled'),
                      backgroundColor: theme.colorScheme.errorContainer,
                      labelStyle: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                        fontSize: 12,
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('EEE, MMM d · h:mm a')
                        .format(activity.eventDate.toLocal()),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (activity.location != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        activity.location!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (activity.eventType != null) ...[
                const SizedBox(height: 8),
                Chip(
                  label: Text(_toTitleCase(activity.eventType!)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
