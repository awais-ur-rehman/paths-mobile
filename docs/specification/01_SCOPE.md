# Paths — Scope Doc

Version 1.0 • 17 October 2026

## 1. Product purpose

Help adults discover and connect with people they were near at approximately the same time in the real world. Primary language: friendship and networking. A user may form a romantic connection, but neither app behavior nor review submissions should conceal the actual service. Launch planning assumes Pakistan, initially a geographically concentrated pilot.

Success means a user can register, complete a profile, optionally submit identity documentation, opt into encounter detection, see a legitimate encounter, privately save that person, send a request, and chat after acceptance. The app must make location limitations understandable and allow users to stop discovery or delete their data.

## 2. Confirmed decisions

| ID | Decision |
|---|---|
| D01 | Android and iOS Flutter app; web is an admin portal |
| D02 | Background encounters plus foreground nearby discovery |
| D03 | Approximate areas visible to others; no exact positions or routes |
| D04 | Ages 18+ only; friendship/networking focus |
| D05 | Email/name/password registration, email OTP verification, password recovery |
| D06 | Profile photo, gender, username, age and bio |
| D07 | CNIC submission optional, skippable, no access restrictions |
| D08 | Admin approves/declines CNIC and can deactivate accounts |
| D09 | Likes are private saves; connection request is separate |
| D10 | Acceptance is required for text chat |
| D11 | Private profile exposes basic details; posts require accepted connection. Public profile posts visible immediately to authorized viewers |
| D12 | Like/request eligibility requires actual detected simultaneous proximity; radius alone is insufficient |
| D13 | Both participants receive encounter push notifications, subject to OS delivery and preferences |
| D14 | CNIC images retained as records while account exists |
| D15 | Account deletion removes personal data, including sent messages from recipients' histories |
| D16 | Backend NestJS + PostgreSQL/PostGIS; admin React/Vite + shadcn/ui |
| D17 | Separate backend, admin and mobile repositories; backend Docker Compose |
| D18 | Planning scale: 10,000 registered / 1,000 daily active users |
| D19 | Google and Apple sign-in included, implemented as final feature phase |

## 3. Release scope

### Mobile

Splash; single onboarding screen; sign-in/sign-up; purpose-specific OTP; forgot/set password; profile setup; optional CNIC submission; location/notification disclosures; Home map with encounter list fallback; Likes and requests; camera capture and profile upload; connections and text chat; own/other profile; settings; block/report; account deletion.

Bottom navigation: Home, Likes, Camera, Chats, Profile. Camera is an action opening a capture flow, not a persistent feed tab. Incoming/outgoing requests are within Likes. Home shows coarse encounter locations for eligible people; Nearby filters recent encounters around the user's current location.

### Backend

Authentication, user/profile management, verification workflow, location ingestion, encounter evaluation, privacy-filtered discovery, likes, requests, connections, chat, media processing, notifications, moderation, deletion orchestration, rate limits, audit and monitoring. Modular monolith with separate worker process from the same backend repository.

### Admin web

Admin sign-in with MFA; review queue and protected CNIC viewer; approve/decline with reason; account search/details; deactivate/reactivate; report review, prepublication image safety review and content removal; operational counts; scoped audit views. No routine access to live user coordinates or all private messages. Report evidence access is permission controlled.

A minimal public privacy/support/account-deletion page is included in the web repository for store requirements. It does not become a user web application and must not load admin data.

## 4. Explicit exclusions

- Image/sticker/voice/video chat, calls, groups, stories, livestreaming.
- Public social feed, followers, post comments or post likes; profile grid only.
- Payments, subscriptions, ads, boosts, compatibility scores, swiping.
- Exact live tracking, travel history, arbitrary address search for people.
- Facial recognition, liveness checks, OCR identity extraction or NADRA integration.
- Venue membership certainty, indoor room/floor detection, Bluetooth encounter exchange.
- Multi-region infrastructure, Kubernetes, dedicated microservices, ML matching.
- Web consumer experience and automatic discovery of non-users.

## 5. Recommended defaults — change through a recorded decision

| Area | Proposed baseline |
|---|---|
| Profile privacy | Private by default; explicit public toggle |
| Age | Collect date of birth privately; derive age; reject under 18 server-side |
| Gender | Man, woman, another identity, prefer not to say; no gender filtering in v1 |
| Profile fields | Photo + username + DOB + gender choice required; bio optional, max 300 chars |
| Map | 1 km default view radius; 0.5/1/3/5 km filters on coarse encounter areas only |
| Encounter history | 30 days for unsaved discovery |
| Saved eligibility | An unexpired encounter permits saving/requesting; save creates durable eligibility until unlike, block or deletion |
| Request | Expires after 14 days; reject/cancel/expiry prevents resend for seven days |
| Repeated encounter alerts | At most one alert per pair per six hours; global user notification budget |
| Media | One image per post; optional caption 500 chars; 10 MB input limit; thumbnails and optimized derivative |
| CNIC | Front image required, back optional; explain retained records and manual review |
| CNIC review operations | Target two business days, not guaranteed automatic approval |
| Retention | Raw locations 24h; candidate evidence <=10 min; live deletion <=24h; backups <=7 days |
| Language | English first; localization keys and Urdu-compatible architecture from day one |
| Device baseline | Proposed Android 10+, iOS 16+; confirm with selected Flutter/plugins in Phase 0 |

Privacy/discovery pause stops new collection and matching, removes current discovery listings, and purges local pending fixes. It does not silently unfriend existing connections or erase their permitted profile access. Explain this distinction in Settings.

## 6. Scope boundaries that protect feasibility

“Live” means the server promptly processes fresh fixes it actually receives. A push is a notification attempt, not proof of device delivery. Delayed offline records may create historical encounters, but not misleading “just now” notifications.

A location match is an estimate. Separate cafés across a street, stacked floors, GPS drift and sparse sampling can cause mistakes. Favor conservative matches and honest labels over fabricated precision. Product owner must accept measured misses before launch.

## 7. Dependencies and launch gates

- Real devices, developer accounts, APNs/FCM credentials, email sender/domain.
- Licensed visual assets and remaining screen designs; exact font identification remains an asset handoff requirement.
- Tile provider or region-specific self-hosted tile pipeline; storage and email have operating costs.
- Actual staff for reports/CNIC review; published privacy, terms, community and child-safety standards.
- Local review of sensitive identity/location processing, cross-border vendors and Pakistan launch requirements.
- Verified delete/restore drill, authorization tests, battery evidence and store permission disclosures.

## 8. Delivery approach

Compare three options: continuous high-frequency tracking (more timely, battery-heavy); passive low-power updates (better battery, misses brief crossings); adaptive native tracking (selected, more engineering, balanced but still best effort). Prove the selected approach first. Subsequent phases deliver authentication, encounter discovery, social connections, posts/chat, admin, deletion/hardening, social sign-in, then release validation.
