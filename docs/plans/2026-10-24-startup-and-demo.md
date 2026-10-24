# Startup, navigation and demo refresh

Owner request: one splash until validated session/setup destination; preserve normal signed-out/setup/restricted flow; diagnose rapid-navigation failures; use realistic licensed demo photos and several Islamabad/Mirpur encounter areas. Plan secure caching, do not silently persist private media or weaken authorization.

1. Reproduce warm restore purging tracking/media and profile refresh discarding loaded state; test repeated/concurrent restore, logout/restriction/cancellation and stale response behavior.
2. Hold the native first frame through session and setup routing; release once at a real destination or actionable error, never indefinite splash. Remove decorative session spinner and use a profile skeleton only for first load. Revalidate session on resume while preserving live resources on success; purge on cold boot/logout/restriction.
3. Keep loaded own-profile surface during ordinary refresh, bounded refresh requests and account isolation. Broader persistent caching remains a written plan, including measurement, threat boundaries, invalidation and success gates.
4. Licensed photo assets for explicitly synthetic local fixture accounts only; idempotent fixture seed with distinct coarse locations in Islamabad/Mirpur, no location samples/push and no changes to real owner profile/verification/blocks. Record sources/licenses.
5. Full relevant mobile/backend checks, offline ARM64/kernel, real local seed/read-back checks, review diff, update statuses and push draft branches. Owner Android only; no iOS build/main promotion. Unspecified API failure remains unproven until evidence; reproduce request bursts and report scope.
