# Task 13 performance and field evidence

No physical phone, emulator or iOS runtime was operated by the implementation agent. Eight-hour battery, labeled precision/recall and profile-mode frame/memory results remain **awaiting device test**. Android builds do not verify iOS.

Private images now fetch only while their route is visible and the app is foregrounded. Hidden/background routes cancel requests and release owned decoded pixels; thumbnail/full changes reauthorize the requested variant. Widget regressions verify these transitions. The map is not constructed in an inactive tab. These checks do not measure native map memory or platform compositor behavior.

The full journey starts the production app, uses its real auth/repository stack and existing native location tracker, navigates tabs/scrolls three times, collects aggregate frame/RSS counters, then verifies tracking queues are empty after logout. It requires a disposable account with completed profile and production tracking enabled. It never creates a second native tracker. It logs no coordinates, messages, credentials or profile content.

Run in **profile mode** using the owner instructions in [task13-device.md](testing/task13-device.md). Debug timing cannot establish the 60 Hz goal. Separate build/raster p95 and over-budget frames are reported; a 16.67 ms frame budget is a 60 Hz reference, not a guarantee for every display. RSS includes native allocations and private decoded images; Flutter's global image cache excludes the private image owner's pixels. A sampled peak is not a full allocation trace. Use DevTools to inspect repeated image/map navigation and rebuilds before drawing a memory-leak conclusion.

Battery tooling records only aggregate battery values and timestamps. Matched baseline/tracking runs require the same phone, at least eight hours each, durations within fifteen minutes and no charging. The owner must confirm the entire runs were unplugged and similarly used: endpoint flags alone cannot prove this. Additional drain <=3 percentage points is an experimental target, not an advertised battery promise.

Coverage tooling consumes owner-labeled scenarios. Unperformed rows stay pending. Precision >=90% requires actual ground truth and sufficient repeated cases; recall is reported separately. Adjacent floors, approximate permission, force-stop and OS power restrictions are explicit limitations. No GPS-only system can guarantee indoor floor separation or uninterrupted delivery.

Automated accessibility tests cover 320–1024 logical-pixel layouts at 200% text, Android touch targets, labels, contrast and reduced motion. Existing reference goldens remain regression evidence; owner screen-reader, native permissions and full screen-by-screen visual acceptance remain separate. No broad visual redesign was introduced.

See [task13-evidence.md](testing/task13-evidence.md) for executed checks and scope. API contract remains 1.11.0.
