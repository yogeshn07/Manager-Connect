# Requirements

## Overview

Manager Connect is a private mobile application for a closed community of 15–20 managers within an organization. It serves as an engagement and relationship-building platform — not a productivity or HR tool.

## Core Requirements Summary

### Must Have (V1)

| # | Requirement |
|---|-------------|
| R01 | Invite-only user registration with admin approval |
| R02 | Manager directory with profiles (name, role, photo, bio, interests) |
| R03 | Community feed with posts, reactions, comments, and @mentions |
| R04 | Pinned admin announcements displayed at the top of the feed |
| R05 | Connect Buddy system account that auto-posts welcome messages, achievements, event/poll reminders, monthly highlights, and memories into the feed |
| R06 | Events module supporting Games (Cricket, Badminton, Pickleball, Table Tennis, Other), Outings, and Social Connect (Coffee Connect, Lunch Meetup, Dinner Meetup, Other) |
| R07 | Event RSVP (Going / Not Going / Maybe) and automated reminders (24h and 1h before) |
| R08 | Polls — create, vote, view results; available in V1 |
| R09 | Post-event attendance recording by admin (Attended / Absent per member) |
| R10 | Event history archive |
| R11 | Fitness Challenges (steps, distance, duration goal tracking with leaderboard) |
| R12 | Wellness Challenges (custom goal tracking) |
| R13 | Personal Analytics (member's own activity, attendance, challenge, and recognition data) |
| R14 | Community Analytics (aggregate engagement metrics across the group) |
| R15 | Community Health Score (composite metric reflecting overall participation) |
| R16 | Monthly Rankings and All-Time Rankings (participation and engagement based) |
| R17 | Monthly Recognition and Community Recognition (peer shout-outs surfaced in Analytics) |
| R18 | Push notifications for events, challenges, polls, mentions, Connect Buddy updates, and recognitions |
| R19 | Admin panel: member management, content moderation, announcements, Connect Buddy management, attendance recording |
| R20 | Secure, invite-only access — no public registration |

### Should Have (V1 stretch)

| # | Requirement |
|---|-------------|
| R21 | Photo sharing within posts and events |
| R22 | Event calendar view |
| R23 | Profile customization (interests, goals) |
| R24 | In-app notification inbox |

### Nice to Have (V2+)

| # | Requirement |
|---|-------------|
| R25 | Integration with health platforms (Apple Health, Google Fit) |
| R26 | Anonymous suggestion box |
| R27 | Dark mode |
| R28 | Web dashboard |

## Constraints

- **User Scale:** 15–20 users maximum at launch; designed to scale to 50 without architecture changes.
- **Platform:** iOS and Android (Flutter cross-platform).
- **Theme:** Light mode only in V1. Dark mode is not in scope.
- **Privacy:** All data is internal and organizational. No third-party social logins.
- **Access:** Invite-only. No self-registration.
- **Data Residency:** Hosted on cloud infrastructure with standard enterprise data handling.

## Out of Scope

- In-app messaging (direct messages or group chat) — removed entirely
- Performance reviews or goal tracking
- HR system integrations
- Public-facing features
- Web dashboard (V1)
- Dark mode (V1)
