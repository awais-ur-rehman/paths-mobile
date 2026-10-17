# Paths — Product Requirements Document

Version 1.0 • 17 October 2026 • Decisions: [Scope](01_SCOPE.md)

## 1. Users and jobs

- Member: reconnect with an adult encountered nearby without broadcasting an exact location.
- Connected member: exchange text and see connection-only posts.
- Verification reviewer: review a voluntarily supplied CNIC and record a defensible decision.
- Moderator: investigate reports, remove offending posts, deactivate/reactivate accounts.
- Administrator: manage staff permissions and operational settings without unrestricted sensitive-data browsing.

## 2. Product invariants

1. No account can create a like/request without server-verified encounter eligibility.
2. No chat send succeeds without an active accepted connection and absence of blocks/deactivation/deletion.
3. Private likes never notify their subject and are not returned by a “who liked me” API.
4. Unverified users have the same product capabilities as verified users.
5. Coordinates, exact distance, exact encounter timestamp, CNIC and DOB never enter another user's profile response.
6. Account deletion removes the deleting user's messages from both participants' app histories.
7. The map never implies that an encounter marker is a person's live location.
8. Permission denial preserves existing connections/chat/profile access.

## 3. Functional requirements and acceptance criteria

| ID | Requirement | Acceptance criteria |
|---|---|---|
| AUTH-01 | Email signup | Name, email, password and terms consent validated server-side; duplicate handling avoids unnecessary enumeration; unverified account cannot discover others |
| AUTH-02 | OTP | Six digits, five-minute expiry, five guesses per challenge, 60-second resend cooldown; newest challenge invalidates previous; one-use and purpose-bound |
| AUTH-03 | Sign-in/session | Successful login resumes correct setup state; invalid/expired refresh clears session; deactivation blocks access immediately |
| AUTH-04 | Recovery | Generic response for email; reset OTP yields narrowly scoped one-use reset token; new password revokes all sessions |
| AUTH-05 | Social providers | Google and Apple both implemented in final feature phase; backend verifies provider token; no silent merge based solely on matching email |
| PROF-01 | Setup | Photo, unique username, DOB/adult gate, gender choice; optional bio; no location collection before disclosure/consent |
| PROF-02 | Privacy | Private basic card visible to eligible viewers; posts require connection; privacy toggle removes unauthorized cached content on next sync |
| PROF-03 | Edit | Name/bio/photo/gender/privacy editable; username uniqueness enforced; DOB correction requires support to discourage gate bypass |
| VER-01 | Optional CNIC | Skip always available; submitting/declining/pending states never block normal use |
| VER-02 | Review | Only authorized reviewer sees document; decision/reason/time recorded atomically; user notified; approved badge shown consistently |
| VER-03 | Badge meaning | Tap explains “Document reviewed by Paths”; no government-check or safety guarantee |
| LOC-01 | Consent | Explain exact server-side matching and coarse public display; foreground before background request; revocation/pause stops new processing |
| LOC-02 | Tracking status | Active, background best effort, paused, permission needed, inaccurate, offline states distinguishable; no guaranteed “always live” label |
| ENC-01 | Match | Spatial proximity plus overlapping fresh observations required; stale, inaccurate, impossible or duplicate evidence cannot unlock requests |
| ENC-02 | Eligibility | Server checks recent encounter or durable saved eligibility at mutation time; spoofed target ID alone returns forbidden/not found |
| ENC-03 | Home | Approximate historical markers and eligible profile list; radius filter does not create new eligibility; blocked/deactivated/deleting users absent |
| ENC-04 | Alerts | Queue notifications for both parties after commit; apply preferences, dedup and rate caps; generic lock-screen text |
| LIKE-01 | Save | Idempotent save/unsave; saved page shows private bookmarks and request state; subject gets no like alert |
| REQ-01 | Request | One pending/accepted relationship per unordered pair; only receiver can accept/decline; sender can cancel |
| REQ-02 | Race handling | Concurrent inverse requests do not auto-connect; second sender is directed to incoming request to accept explicitly |
| REQ-03 | Expiry | Pending request expires after 14 days; seven-day resend cooldown after decline/cancel/expiry; accepted connections remain until removed |
| CHAT-01 | Chat | Text up to 4,000 characters, cursor history, sent/failed states, retry with same client message ID; no duplicate messages |
| CHAT-02 | Reconnect | Server ACK only after durable write; history sync repairs lost socket events; no permanent socket maintained for background chat |
| CHAT-03 | Connection removal | Disconnect disables sends and connection-only post access; retained nondeleted history is read-only |
| POST-01 | Camera | Camera permission requested on use; capture/retake/preview/caption/upload/cancel supported; gallery alternative if permission denied |
| POST-02 | Upload | Validate file bytes, decode/re-encode, strip metadata, generate derivatives; pending/rejected media never appears as published |
| POST-03 | Grid | Own posts manageable; public or connected viewers see allowed posts; no post likes/comments in v1 |
| SAFE-00 | Content filtering | Pilot user-visible images require safety review before publication; text uses server-side prohibited-content rules and report escalation; pending photos use neutral placeholder |
| SAFE-01 | Block | Immediate bilateral discovery/request/send denial; cancel requests; disconnect; remove saved links both ways; unblock does not restore connection |
| SAFE-02 | Report | Profile/post/message reporting, category and optional explanation; report ID and acknowledgment; admin triage flow |
| SAFE-03 | Underage report | High-priority review and temporary restriction when evidence warrants; 18+ self-declaration is not identity-based age assurance |
| SET-01 | Settings | Profile privacy, encounter pause, push categories, blocked list, verification status, password, sessions/logout, policies/support/deletion |
| DEL-01 | Delete | Recent reauthentication, explicit consequence screen, immediate revoke/hide, asynchronous erasure including sent messages/CNIC/object versions |
| DEL-02 | External path | Public Paths deletion page works without installing app; email OTP authenticates request; inaccessible-email cases use protected support flow |
| ADM-01 | Staff auth | Provisioned accounts, MFA, roles, session timeout, CSRF defense; no public admin registration |
| ADM-02 | Account action | Deactivate with reason and audit; no tracking/chat/push afterward; reactivate explicitly; deletion remains available |

## 4. Discovery and relationship semantics

Public means posts can be viewed by a signed-in eligible viewer, not that the account is indexed on the public web. No global username search for strangers in v1. Username search within existing connections is allowed.

Home offers Recent (default, last 30 days) and Nearby (encounter area within selected radius, latest 24h). The presence of a person on Nearby does not assert they are still there. Display “Encounter area · earlier today,” never “currently 37 m away.” If location is unavailable, Recent remains available and Nearby asks for permission.

A save made while eligible persists beyond encounter history expiry, carrying only a minimal pair eligibility record. Unsave removes that durable eligibility if there is no active request/connection; a fresh encounter may be needed later. An existing request may still be accepted after its source encounter ages out. No exact location is retained solely to justify a saved profile.

Repeated observations within a 30-minute pair inactivity gap form one session. A later session increments the encounter count but alert cooldown applies. Configure thresholds server-side with a version, not per-user hidden algorithm changes.

## 5. Abuse and privacy behavior

Provide block/report from profile and chat, and report from a post. Blocking may hide the conversation by default; it must remain possible to report existing evidence without re-enabling messaging. Generic “This profile is unavailable” avoids disclosing whether the reason is block or deletion.

Generic push examples: “You crossed paths with someone. Open Paths to see more.” “You have a new connection request.” “You have a new message.” Do not put names, message bodies, coordinates or CNIC status details on the lock screen by default. No compatibility percentage in any screen.

Report evidence is scoped to submitted content; moderators do not receive an unrestricted private-message search. Remove identifying report evidence if the associated user is deleted under the requested policy; retain only nonidentifying category totals. This limits retrospective investigation and must be understood operationally.

## 6. Acceptance targets — proposed, measured before release

| Metric | Target and measurement boundary |
|---|---|
| API latency | p95 <500 ms for normal reads/writes at agreed pilot load, excluding upload bytes/external email/push |
| Encounter processing | p95 <=5 seconds from second qualifying evidence commit to encounter creation; excludes device sampling and network delay |
| Foreground chat | p95 <=2 seconds from API receipt to connected recipient event under healthy network |
| Availability | Pilot objective 99.5% monthly for API; a single VM cannot guarantee this |
| UI | Smooth 60 Hz scrolling on baseline devices; frame profiling, not claims from widget style alone |
| Accessibility | Text scaling to 200%, screen-reader labels, contrast checks, 48 logical-pixel targets |
| Deletion | Immediate denial/visibility removal; live-store purge within 24h; backup expiry within seven days |
| Battery | Experimental goal <=3 percentage points additional battery use over eight hours against matched idle baseline; record per-device results |
| Encounter quality | At least 90% precision in labeled pilot scenarios; report recall separately for street/café/locked-device cases; no launch claim of universal detection |

Battery/precision goals are engineering gates, not guarantees from chosen libraries. If they fail, adjust sampling/product claims with the owner before broad release.

## 7. Privacy-preserving measurement

Measure signup completion, permission opt-in, encounters, saves, requests accepted, first message, crash-free sessions and deletion duration. Store coarse aggregate daily counts; no coordinates, CNIC, raw messages or persistent tracking identifiers in analytics. Suppress very small geographic cohorts; omit geographic analytics initially. Consent choices cannot be overridden for metrics.

## 8. Launch readiness

All critical authorization, deletion, permission and duplicate-delivery tests pass. Real-device tracking report includes locked, killed, offline, power-saver and stationary conditions. Moderation team, privacy/deletion pages, store metadata, age settings and support route are operational. Google/Apple sign-in has passed account-linking/deletion tests. Documentation describes limitations and remaining nonblocking issues honestly.
