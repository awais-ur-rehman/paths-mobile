# Paths — product and engineering documentation

Version: 1.0 • Research date: 17 October 2026 • Owner: Awais Ur Rehman

This package is a proposed implementation baseline, not a claim that the app or background-location prototype has been built. Confirmed requirements are distinguished from recommended defaults. Read the documents in numerical order. No product code or repositories were created.

## Documents

1. [Scope Doc](01_SCOPE.md): commitments, exclusions, assumptions, decision register.
2. [PRD](02_PRD.md): user stories, behavior, acceptance criteria, operational requirements.
3. [TRD](03_TRD.md): tracking, matching, APIs, data model, security, deletion, deployment.
4. [Complete App Flow](04_APP_FLOW.md): routes, screens, state transitions, failures.
5. [System and UI Design](05_SYSTEM_UI_DESIGN.md): architecture, reference interpretation, tokens, components, responsive rules.
6. [Implementation Plan](06_IMPLEMENTATION_PLAN.md): phases, checklist tasks, interfaces, verification gates.
7. [Research and Sources](07_RESEARCH.md): primary-source findings, alternatives, limitations, source links.

## Read this before implementation

- Paths supports adults meeting through real-world encounters, with friendship/networking presentation and truthful descriptions of functionality.
- Users can only like/request people with a qualifying encounter. The map is not a directory of arbitrary nearby strangers.
- Likes are private bookmarks. A separate accepted request unlocks chat.
- Native operating systems control background execution. Reliable detection of every passing stranger with negligible battery use is not a feasible promise. Phase 0 determines measured coverage and battery cost on real phones.
- Exact coordinates stay server-side for matching. Other people see coarse encounter areas, not live tracking. Neither GPS nor H3 proves that two people entered the same café.
- CNIC verification is optional and changes no feature entitlement. Retain submitted images during account lifetime, delete on account deletion. A manual review is not NADRA verification or proof of safety.
- Deletion immediately removes access/visibility; proposed completion targets are 24 hours for live stores and seven days for expiring backups. These are design defaults, not an assertion that platform policies require these exact windows.
- Flutter + Cubit/BLoC; NestJS + PostgreSQL/PostGIS; React/Vite/shadcn admin. Three repositories. Docker Compose locally and on a VM; no microservices at launch.
- Google and Apple sign-in are part of this release and the final feature phase. Release verification still follows that phase.

## Evidence and uncertainty

Research links are in 07_RESEARCH.md. Numerical product thresholds, service-level objectives, sizing, and colors are recommendations, not externally proven facts. Version pinning and package license checks occur at implementation kickoff. Current Pakistan-specific legal applicability needs a qualified local review before public release; the referenced draft bill is not treated as enacted law.

The supplied IMG_4661.JPG contains three composited reference screens. Preserve its composition, surfaces, spacing, rounded shapes and photo treatment; use Paths branding. Exact design parity requires original assets/font names or further supplied screens. Do not invent match percentages, interests, occupations, boosts, or swipe features shown in the reference.
