# Paths — Research, Decisions and Sources

Research date: 17 October 2026. Primary sources are preferred. Source facts below are separate from proposed Paths thresholds and architecture decisions. Recheck store policies, dependencies and hosting limits before implementation/release.

## 1. Main findings

### Background discovery is feasible, comprehensive live detection is not guaranteed

Android documents throttling of normal background location and warns that sustained near-real-time updates cost battery [R01]. Apple recommends choosing location services and update frequency carefully [R02]. Therefore Paths should adapt sampling and validate on real hardware; neither Flutter nor a server algorithm can recover a crossing for which no timely device observations exist.

For Paths, “live” is a pipeline latency goal after receiving usable evidence. A one-minute request interval does not mean the OS delivers once per minute. A geofence is useful for movement context, not a scalable, exact peer-to-peer crossing detector. Stale stationary fixes must expire rather than imply continuing presence.

### H3 and maps solve different problems

H3 is a hierarchical geographic index developed at Uber [R03]. It is not an Uber map service. MapLibre handles display, a tile source supplies cartography, and PostGIS handles initial spatial matching. PostGIS ST_DWithin supports indexed distance queries and geography distances in meters [R04]. Adding H3 at launch would add complexity without proven benefit; future candidate bucketing still requires neighbor/time/distance checks.

### Free source code does not mean zero operating cost

MapLibre can support an open-source map stack, but tiles, data generation and egress still cost resources. OSM public tile servers have usage restrictions and no SLA [R05–R06]. Do not assume unlimited free map hosting. A managed tile allowance is easiest for pilot; self-host a licensed regional dataset later if usage economics justify it.

The current Transistorsoft background-geolocation README requires release-build licenses for both platforms [R07]; older Android-only licensing advice is stale. Its mature implementation may save engineering time, but it is not the selected no-license-fee baseline. Build/maintain the small native bridge and measure its cost. geolocator is useful but does not by itself settle process-death, scheduling and native background orchestration [R08].

### Flutter architecture should isolate updates, not prohibit local widget state

Flutter recommends separating UI and data responsibilities, repositories, immutable models, and go_router [R09]. Paths adapts those principles to Cubit/BLoC. BlocSelector narrows rebuilds to selected immutable state [R19]; it does not magically optimize an entire tree. Stateless screen roots remain compatible with small StatefulWidgets that manage controllers. Dio supplies transport/interceptor/cancellation primitives; refresh serialization and safe retries are application responsibilities [R20].

### Deletion includes an external entry point

Apple requires an in-app account-deletion path and documents revoking Sign in with Apple tokens [R10]. Google also requires a discoverable web deletion resource for covered apps, including users who uninstalled the app [R11]. The proposed public deletion page is therefore a small addition to the admin web repository, not a consumer web application.

The user's full-erasure requirement is stricter than treating deactivation as deletion. The proposed 24h live/seven-day backup windows are design targets, not platform-prescribed exact deadlines. Declare actual retention and verify vendor behavior. Referential integrity is preserved through deliberate foreign-key relationships and a retryable external-object purge; anonymizing a display name alone is insufficient.

### Social safety applies beyond dating branding

Apple's UGC rules call for filtering, reporting, blocking and reachable contact information [R12]. Google publishes child-safety standards for social/dating categories, including published standards, reporting and an operational safety contact [R13]. Paths needs these capabilities even with an 18+ audience. Its content and functionality must be represented truthfully. Current Google age-restricted/incidental-dating guidance also warrants review against actual features [R23–R24].

### Hosting advice must reflect current capabilities

Vercel announced WebSocket support in public beta on 22 June 2026 [R14]. It is inaccurate to reject Vercel solely with “WebSockets unsupported.” A full Docker Compose stack still fits a VM more directly; serverless adaptation would need separate data services and worker design. Render supports Docker web services and WebSockets; persistent disks are a distinct option and default service filesystems are ephemeral [R15].

### Pakistan launch requirements remain a release dependency

MoITT's legislation listing labels the May 2023 Personal Data Protection Bill as a draft [R16]. This is not enough to certify the entire current legal position or assume no other duties apply. The historic PTA press-release URL could not be retrieved in this research [R17]. No assertion of current PTA approval, licensing exemption or guaranteed acceptance is made. Have local counsel assess actual service behavior, identity/location retention, vendors, content obligations and applicable current rules. Friendship wording alone is not a legal conclusion.

## 2. Alternatives matrix

| Decision | Selected | Alternative | Why selected / trigger to revisit |
|---|---|---|---|
| Location | Adaptive native bridge | Continuous GPS / commercial SDK | Meets source-control/no-license-fee preference; revisit if field quality/maintenance cost fails |
| Geography | PostGIS | H3 candidate buckets | Meter/time queries first; add buckets only after measured DB bottleneck |
| Map | MapLibre + configurable tiles | Google Maps/Mapbox | Styling and source independence; assess actual tile economics and attribution |
| Backend | NestJS modular monolith | Many microservices | Transactions and deletion easier; split only independently scaling bottlenecks |
| Queue | Valkey + BullMQ OSS | DB-only worker / managed queue | Familiar job model; outbox protects durable delivery; compatibility tested [R18] |
| Storage | Private S3 adapter | Private filesystem on VM | Portable and easier lifecycle management; self-host implies backup/availability work |
| Auth | First-party email + provider adapters | Managed identity platform | Control and portability; higher security implementation responsibility |
| Push | FCM/APNs | Foreground-only sockets | Mobile background notifications need platform services; not replaced by persistent app sockets |
| Admin | React/Vite/shadcn | Next.js | User preference; no server-rendering requirement |
| Deployment | VM Compose baseline | Render services / Vercel adaptation | Exact topology portability; managed services reduce some operations work |

## 3. Cost boundaries

No current vendor price quote is supplied because deployment is a later decision and region/traffic/provider are unresolved. Software-license-free choices still incur VM, media, backups, bandwidth, email delivery, map tiles, developer accounts and human moderation costs. FCM pricing lists Cloud Messaging separately; verify the current no-cost offering and related services before budgeting [R21]. Native APIs depend on Apple/Google ecosystems, so “all open source” would be an inaccurate claim.

Use measured daily sample volume, image storage, egress, peak concurrent users and review workload to obtain quotes. Avoid annual commitments before the physical-device feasibility test. No capacity or battery numbers in this package have been benchmarked; they are transparent planning assumptions.

## 4. Source register

| ID | Primary source | Supports |
|---|---|---|
| R01 | [Android background location limits](https://developer.android.com/about/versions/oreo/background-location-limits), [battery guidance](https://developer.android.com/develop/sensors-and-location/location/battery) | Background throttling and energy trade-off |
| R02 | [Apple location efficiency](https://developer.apple.com/documentation/xcode/accessing-the-device-s-location-efficiently), [background updates](https://developer.apple.com/documentation/corelocation/handling-location-updates-in-the-background) | Platform-specific service/lifecycle design; some Apple API pages require client-side rendering |
| R03 | [H3 introduction](https://h3geo.org/docs/), [indexing](https://h3geo.org/docs/highlights/indexing/) | Geographic indexing; logical vs geometric containment |
| R04 | [PostGIS radius-query guidance](https://postgis.net/documentation/tips/st-dwithin/), [ST_DWithin](https://postgis.net/docs/manual-3.5/en/ST_DWithin.html) | Spatial indexing and geography distance units |
| R05 | [MapLibre Flutter license](https://github.com/maplibre/flutter-maplibre-gl/blob/main/maplibre_gl/LICENSE), [package](https://pub.dev/packages/maplibre_gl) | Renderer and license review |
| R06 | [OSM tile policy](https://operations.osmfoundation.org/policies/tiles/), [vector policy](https://operations.osmfoundation.org/policies/vector/) | Tile service limits, attribution and availability |
| R07 | [Transistorsoft current README](https://github.com/transistorsoft/flutter_background_geolocation/blob/master/README.md) | Current release licensing on both platforms |
| R08 | [geolocator documentation](https://pub.dev/documentation/geolocator/latest/index.html) | Platform configuration and location API scope |
| R09 | [Flutter architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations), [guide](https://docs.flutter.dev/app-architecture/guide) | Separation, repositories, immutability and navigation |
| R10 | [Apple account deletion](https://developer.apple.com/support/offering-account-deletion-in-your-app/), [token revocation reminder](https://developer.apple.com/news/?id=12m75xbj) | In-app deletion and Apple token handling |
| R11 | [Google account deletion](https://support.google.com/googleplay/android-developer/answer/13327111) | In-app/external pathway, disclosures and data handling |
| R12 | [Apple review guidelines](https://developer.apple.com/app-store/review/guidelines/) | UGC safeguards, login services, privacy and truthful review information |
| R13 | [Google child-safety standards](https://support.google.com/googleplay/android-developer/answer/14747720) | Social/dating safety standards |
| R14 | [Vercel WebSocket announcement](https://vercel.com/changelog/websocket-support-is-now-in-public-beta) | June 2026 public beta; verify current limits at deployment |
| R15 | [Render Docker](https://render.com/docs/docker), [WebSockets](https://render.com/docs/websocket), [disks](https://render.com/docs/disks), [deploys](https://render.com/docs/deploys) | Deployment and persistence behavior |
| R16 | [MoITT legislation listing](https://www.moitt.gov.pk/Legislations) | Listed draft status; not a comprehensive legal opinion |
| R17 | [Historic PTA release URL](https://www.pta.gov.pk/en/media-center/single-media/p-ta-blocks-five-dating/live-streaming-applications-010920) | Retrieval unavailable; do not treat as verified current policy |
| R18 | [BullMQ](https://bullmq.io/), [compatibility](https://docs.bullmq.io/guide/redis-tm-compatibility/) | OSS queue and compatibility checks |
| R19 | [flutter_bloc API](https://pub.dev/documentation/flutter_bloc/latest/), [BlocSelector](https://pub.dev/documentation/flutter_bloc/latest/flutter_bloc/BlocSelector-class.html) | Selective state-driven rebuilds |
| R20 | [Dio](https://pub.dev/packages/dio) | Interceptors, cancellation and request handling |
| R21 | [Firebase pricing](https://firebase.google.com/pricing) | Push service cost boundary; other services separately metered |
| R22 | [Google background location review](https://support.google.com/googleplay/android-developer/answer/9799150) | Disclosure, permission declaration and review; approval not guaranteed |
| R23 | [Google age-restricted functionality](https://support.google.com/googleplay/android-developer/answer/16302250) | Actual functionality may require minor-access restrictions |
| R24 | [Google incidental dating guidance](https://support.google.com/googleplay/android-developer/answer/16838200) | Review actual functionality rather than category wording alone |
| R25 | [Docker Compose volumes](https://docs.docker.com/reference/compose-file/volumes/) | Persistent containers need explicitly managed volumes |

## 5. What research does not establish

- A precise battery percentage or detection recall for this unbuilt app.
- That a chosen sample threshold proves same-café presence or physical interaction.
- That coarse maps eliminate inference risks in sparsely populated places.
- That a manually uploaded CNIC proves identity, liveness, age or document authenticity.
- Exact font/asset ownership or pixel-perfect recreation from one screenshot.
- A production VM capacity, guaranteed app-store approval or legal permission to launch.

These are covered by validation tasks and explicit release gates rather than invented assurances.
