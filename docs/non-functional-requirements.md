# Non-Functional Requirements

## NFR-01: Performance

| ID | Requirement |
|----|-------------|
| NFR-01.1 | App cold start to usable screen: under 3 seconds on mid-range devices. |
| NFR-01.2 | Feed content loads within 1.5 seconds on a 4G connection. |
| NFR-01.3 | Push notifications are delivered within 10 seconds of the triggering event. |
| NFR-01.4 | Image uploads complete within 5 seconds for photos up to 5 MB. |
| NFR-01.5 | The system sustains all features with 20 concurrent active users with no degradation. |

---

## NFR-02: Reliability and Availability

| ID | Requirement |
|----|-------------|
| NFR-02.1 | Backend availability target: 99.5% uptime (excludes planned maintenance). |
| NFR-02.2 | The app must function in read-only mode during backend unavailability (cached content visible). |
| NFR-02.3 | Data is backed up daily with a retention period of 30 days. |
| NFR-02.4 | No single-point-of-failure in the backend infrastructure. |

---

## NFR-03: Security

| ID | Requirement |
|----|-------------|
| NFR-03.1 | All data in transit is encrypted using TLS 1.2 or higher. |
| NFR-03.2 | All data at rest is encrypted using AES-256 or equivalent. |
| NFR-03.3 | Authentication tokens are stored in device secure storage (Keychain/Keystore), not AsyncStorage. |
| NFR-03.4 | Row-level security (RLS) policies ensure users can only access their own and community-wide data. |
| NFR-03.5 | Admin actions (user management, content deletion) are logged with timestamp and actor ID. |
| NFR-03.6 | No third-party analytics SDK may exfiltrate PII outside the organization's approved cloud boundary. |
| NFR-03.7 | The app passes OWASP Mobile Security Top 10 review before production launch. |

---

## NFR-04: Scalability

| ID | Requirement |
|----|-------------|
| NFR-04.1 | Architecture must support scaling from 20 to 100 users with no code changes. |
| NFR-04.2 | Database queries must use indexed fields for all list and feed views. |
| NFR-04.3 | Media storage must support growth to 10 GB without architecture changes. |

---

## NFR-05: Usability

| ID | Requirement |
|----|-------------|
| NFR-05.1 | First-time users must complete onboarding within 3 minutes without external help. |
| NFR-05.2 | All primary actions (RSVP, post, recognize) must be reachable within 2 taps from any main screen. |
| NFR-05.3 | The UI must meet WCAG 2.1 AA contrast and tap-target size standards. |
| NFR-05.4 | The app must support both iOS and Android with a consistent experience. |

---

## NFR-06: Maintainability

| ID | Requirement |
|----|-------------|
| NFR-06.1 | Codebase must have a minimum of 60% unit test coverage on business logic. |
| NFR-06.2 | All modules must be independently deployable without breaking others. |
| NFR-06.3 | No build should rely on environment secrets committed to the repository. |
| NFR-06.4 | Build and deployment must be fully automated via CI/CD pipeline. |

---

## NFR-07: Privacy

| ID | Requirement |
|----|-------------|
| NFR-07.1 | The platform collects only the minimum data necessary to operate the described features. |
| NFR-07.2 | User data is not shared with HR systems, payroll, or third-party platforms. |
| NFR-07.3 | On user removal, their PII (name, photo, bio) is soft-deleted within 24 hours and hard-deleted within 30 days. |
| NFR-07.4 | No behavioral tracking (keystroke, location, or screen recording) is implemented at any time. |
