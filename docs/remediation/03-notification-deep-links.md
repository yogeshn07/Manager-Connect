# REM-03: Notification Deep Linking

## Problem

Notifications store `reference_type` and `reference_id` in the `notification_inbox` table, but tapping a notification in the Notification Center does nothing — it only marks as read. The user cannot navigate to the referenced content (post, activity, challenge, recognition).

## Severity: MEDIUM

## Risk: Engagement gap — notifications exist but don't drive users to content

## Affected Modules

- Notifications (tap action)
- Feed (post deep link target)
- Events (activity deep link target)
- Challenges (challenge deep link target)
- Recognition (recognition deep link target)

## Architecture

The `notification_inbox` table already stores:
- `reference_type`: `'activity'`, `'challenge'`, `'recognition'`, `'poll'`, `'post'`, `'user'`
- `reference_id`: UUID of the referenced entity

### Route Mapping

| reference_type | Route |
|---------------|-------|
| `post` | `/feed/post/{reference_id}` |
| `activity` | `/events/event/{reference_id}` |
| `challenge` | `/growth/challenge/{reference_id}` |
| `poll` | `/events/poll/{reference_id}` |
| `recognition` | `/feed` (no dedicated recognition detail route) |
| `user` | `/profile` (member profile not implemented yet) |

### Implementation

In `NotificationCenterScreen`, the `onTap` handler for each notification tile should:

1. Call `markRead(notificationId)`
2. Extract `referenceType` and `referenceId` from the notification DTO
3. Use `context.push(route)` to navigate to the target screen

```dart
void _onNotificationTap(NotificationItemDto notification) {
  ref.read(notificationProvider.notifier).markRead(notification.id);
  
  final route = switch (notification.referenceType) {
    'post' => '/feed/post/${notification.referenceId}',
    'activity' => '/events/event/${notification.referenceId}',
    'challenge' => '/growth/challenge/${notification.referenceId}',
    'poll' => '/events/poll/${notification.referenceId}',
    _ => null,
  };
  
  if (route != null) context.push(route);
}
```

## Files Impacted

| File | Change |
|------|--------|
| `notification_center_screen.dart` | MODIFY — add tap-to-navigate logic |
| `notification_dto.dart` | VERIFY — referenceType and referenceId already in DTO |

## Dependencies

- All target routes already exist in the router
- All target screens already load by ID
- NotificationItemDto already has `referenceType` and `referenceId` fields

## Validation Steps

1. Create a recognition (triggers `recognition_received` notification)
2. Open Notification Center
3. Tap the notification
4. Verify navigation to the feed (or appropriate screen)
5. Verify notification is marked as read
6. Test with activity, challenge, poll notifications

## Rollback Plan

Remove the navigation logic from `onTap`. Revert to mark-read-only behavior.

## Estimated Effort: 1-2 hours
