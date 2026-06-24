# REM-05: Admin Missing UI Actions (Pin/Unpin + Remove User)

## Problem

Two Edge Functions have working backends but no frontend UI buttons:
- `pin-announcement` — pin/unpin posts to feed top
- `remove-user` — anonymize and deactivate a member (PII removal)

## Severity: LOW

## Risk: Feature gap — admin capabilities exist but are inaccessible from UI

## Affected Modules

- Admin Dashboard (pin/unpin)
- Admin Member Management (remove user)

## Architecture

### Pin/Unpin

`AdminRepository` already has `pinPost(postId)` and `unpinPost()` methods. The admin dashboard needs a "Pin Post" card or button that:
1. Shows current pinned post (if any) via `pinned_announcements` REST query
2. Provides "Unpin" action
3. Provides "Pin new" action with a post picker

### Remove User

`AdminRepository` does NOT currently have a `removeUser()` method (only deactivate/reactivate). Need to add the method calling `remove-user` EF, then add a "Remove" button to the member management action sheet with a confirmation dialog.

## Files Impacted

| File | Change |
|------|--------|
| `admin_dashboard_screen.dart` | ADD — pin management card/section |
| `admin_repository.dart` | VERIFY `pinPost`/`unpinPost` exist, ADD `removeUser()` |
| `member_management_screen.dart` | ADD — "Remove" button with confirmation dialog |

## Validation Steps

1. Admin pins a post → `pinned_announcements` row created
2. Feed shows pinned post at top
3. Admin unpins → `is_active` set to false
4. Admin removes user → profile anonymized to "Removed Member"
5. Audit log entries created for both actions

## Estimated Effort: 2-3 hours
