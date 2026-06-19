# User Flows

## Overview

This document describes the primary user journeys within Manager Connect. Each flow is mapped from entry point to completion.

---

## UF-01: First-Time Onboarding

**Actor:** New manager (invited by admin)  
**Entry:** Receives invitation link via email or SMS

```
[Receive invite link]
       ↓
[Open app / App Store download prompt]
       ↓
[Enter OTP sent to email or mobile]
       ↓
[Create profile: name, photo, role, bio, interests]
       ↓
[App shows Welcome screen with quick-start tips]
       ↓
[Land on Community Feed — Home tab]
```

**Success Criteria:** User completes profile and views the feed within 5 minutes of receiving the invite.

---

## UF-02: Creating an Activity

**Actor:** Any member  
**Entry:** Taps the Activities tab

```
[Activities tab]
       ↓
[Tap "+" Create Activity button]
       ↓
[Fill in: Title, Date/Time, Location, Description, optional Cost Note]
       ↓
[Tap "Post Activity"]
       ↓
[Activity published — all members notified via push]
       ↓
[Activity appears in Activities list and calendar]
```

**Success Criteria:** Activity is visible to all members and RSVP is open.

---

## UF-03: RSVPing to an Activity

**Actor:** Any member  
**Entry:** Push notification or Activities tab

```
[See activity card in list or notification]
       ↓
[Tap activity to open detail view]
       ↓
[View title, date, location, attendee list]
       ↓
[Tap RSVP button: Going / Not Going / Maybe]
       ↓
[RSVP recorded — attendee list updates in real time]
       ↓
[User receives reminder notification 24h and 1h before event]
```

**Success Criteria:** RSVP is recorded and user sees confirmation.

---

## UF-04: Posting a Recognition

**Actor:** Any member  
**Entry:** Recognition tab or Feed post action

```
[Recognition tab]
       ↓
[Tap "Recognize Someone" button]
       ↓
[Search for or select the recipient(s)]
       ↓
[Choose category tag: Community Contributor / Fitness Champion / Wellness Champion / Event Champion / Most Supportive Manager]
       ↓
[Write recognition message]
       ↓
[Tap "Post Recognition"]
       ↓
[Recognition appears on Recognition Wall]
       ↓
[Recipient receives push notification]
```

**Success Criteria:** Recognition is posted and recipient is notified.

---

## UF-05: Joining and Logging a Wellness Challenge

**Actor:** Any member  
**Entry:** Wellness tab

```
[Wellness tab — see active challenges]
       ↓
[Tap challenge to view details: goal, duration, participants]
       ↓
[Tap "Join Challenge"]
       ↓
[Challenge appears in "My Challenges" section]
       ↓
[Tap "Log Progress" on any active day]
       ↓
[Enter today's progress value]
       ↓
[Leaderboard updates with new entry]
```

**Success Criteria:** Member is joined and can log progress. Leaderboard reflects their entry.

---

## UF-07: Admin — Inviting a New Member

**Actor:** Admin  
**Entry:** Admin Panel

```
[Admin Panel → Members section]
       ↓
[Tap "Invite Member"]
       ↓
[Enter name and email or mobile number]
       ↓
[Tap "Send Invite"]
       ↓
[Invite email/SMS sent with unique registration link]
       ↓
[Admin sees member appear as "Pending" in member list]
       ↓
[On registration completion, status updates to "Active"]
```

**Success Criteria:** Invite sent and admin can track pending vs. active members.

---

## UF-08: Admin — Moderating a Flagged Post

**Actor:** Admin  
**Entry:** Admin receives moderation notification or checks admin panel

```
[Admin Panel → Flagged Content section]
       ↓
[View flagged post with context and reporter]
       ↓
[Choose action: Delete Post / Dismiss Flag]
       ↓
[If deleted: post is removed, original author notified]
       ↓
[If dismissed: flag cleared, no action taken]
```

**Success Criteria:** Flagged content is reviewed and resolved within 24 hours.
