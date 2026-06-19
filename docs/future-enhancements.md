# Future Enhancements

## Overview

This document captures features and improvements that are intentionally out of scope for Manager Connect V1 but are strong candidates for future releases. Items are categorized by phase and priority.

---

## V1.1 (4–6 Weeks Post-Launch)

These are near-term improvements driven by anticipated user feedback after launch.

### Activity Calendar View
- Replace or supplement the activities list with a full monthly/weekly calendar
- Members can see the month at a glance and plan ahead
- Requires: calendar UI component integration (e.g., `react-native-calendars`)

### Polls for Activity Planning
- Any member can create a poll (e.g., "Where should we go? A / B / C")
- Members vote anonymously or publicly (configurable)
- Results shown in real-time with a closing date
- Reduces friction in group decision-making for outings

### Notification Quiet Hours
- Members configure a daily quiet window (e.g., 10 PM – 7 AM)
- Notifications are batched and delivered at the start of the next active window
- Reduces notification fatigue without requiring permanent category opt-out

### Interest-Based Member Discovery
- Members browse profiles filtered by shared interest tags
- "Who else is into running? Who is interested in cricket?"
- Helps the Connector persona find the right people for specific activities

---

## V1.2 (2–3 Months Post-Launch)

Feature additions that enrich the core experience based on observed usage patterns.

### Achievements and Badges
- Milestone badges awarded automatically (e.g., "First Activity Organized", "5 Recognitions Given", "30-Day Streak")
- Displayed on member profiles
- Lightweight gamification to sustain long-term engagement

### Anonymous Suggestion Box
- Members can submit suggestions to the admin anonymously
- Admin receives suggestion in admin panel and can post a response publicly
- Maintains community voice without attribution pressure

### Challenge Category Tags
- Challenges tagged by type: Running / Cycling / General Wellness / Custom
- Members filter the wellness tab by category
- Leaderboard filterable by challenge type

### Rich Media in Recognition
- Option to add a GIF or image to a recognition post
- Makes the recognition wall more visually engaging

---

## V2.0 (6 Months Post-Launch)

Significant platform evolution requiring architectural considerations.

### Health Platform Integration
- Connect Apple Health (iOS) or Google Fit (Android) to auto-sync step counts and workout data
- Wellness challenge progress logged automatically from wearable data
- Reduces manual logging friction for activity-based challenges
- Requires: HealthKit (iOS) and Health Connect (Android) native module integration

### Web Admin Dashboard
- Read-only web interface for the admin to manage users and view engagement without using the mobile app
- Useful for admins who prefer desktop for management tasks
- Built on: Next.js + Supabase client, deployed to Vercel

### Expanded User Base
- Extend the platform to support 50–100 users (e.g., cross-department expansion)
- Architecture is already designed to scale to this level without changes
- Requires: admin onboarding tooling for bulk invitations

### Advanced Recognition System
- Monthly recognition highlights (most recognized member)
- Team recognition (recognize an entire group for a collaborative win)
- Recognition history searchable and filterable
- Optional: recognition points system (no monetary value — purely symbolic)

### Push Notification Digest
- Weekly digest notification: "Here's what happened in Manager Connect this week"
- Summarizes: new activities, top recognition, challenge leaders
- Useful for less-active members who might miss individual notifications

### Event Photo Albums
- After an activity, organizer creates a shared photo album
- Members who attended can add photos to the album
- Album linked to the activity in archive view

---

## Deliberate Non-Features

The following are explicitly out of scope for all foreseeable versions. Recording them prevents scope creep and repeated discussion.

| Feature | Reason Out of Scope |
|---------|---------------------|
| Performance reviews | Contradicts platform purpose; HR tool territory |
| Attendance tracking | Surveillance concern; violates trust |
| Manager ranking or scoring | Creates unhealthy competition |
| Integration with HR systems (Workday, SAP, etc.) | Data separation is a non-negotiable boundary |
| Public profiles or public content | Private community; no external visibility |
| Video calls | Out of scope; existing tools handle this |
| Expense tracking for outings | Finance system territory |
| Manager goal setting | Performance management territory |
