# API contract1.2.0

Pinned openapi/paths.v1.json is byte-identical to the real backend Nest export. Run `python3 tools/generate_api_contract.py`, then `dart format lib/core/network/generated/api_contract.dart`. The tested generator supports required strings/booleans/enums and fails explicitly for unsupported optional/nested shapes. Generated DTOs carry the source SHA256; never edit them manually.

HttpAuthRepository uses separate public and authenticated Dio transports, bounded timeouts and typed safe failures. PlatformTokenVault owns secure session persistence; SharedPreferences holds only install/onboarding/tombstone/device markers. Bootstrap explicitly restores against server metadata. AuthCubit and router guard onboarding/OTP/reset/setup/restriction states. The old private location experiment is isolated at lib/main_phase0.dart.

RefreshCoordinator owns single-flight refresh and at most one authorized replay. The repository persists rotations before replay, rejects stale account generations, retains credentials on temporary outages and clears them on definitive revocation. Requests require an idempotent verb or explicit idempotency key for replay; streams are not replayed and multipart bodies are cloned. Logout identifies the server family using its refresh secret, including a consumed token during a refresh race. No response body, bearer token or DOB is logged.

Public config provides supportEmail/termsUrl/privacyUrl only; SMTP/R2/auth secrets remain server-side. DOB travels only in the private adult-check input and is excluded from account/session metadata. Production auth mutations never return fixture successes.

API1.2.0 added authenticated adult-only GET/PUT /v1/me/profile for private editable details. Input has username/name/gender/bio only. Response excludes DOB and explicitly does not complete setup.

API1.3.0 adds optional visibility to profile writes and required visibility to details; GET /v1/profiles/:id returns an allowlisted own basic summary including calendar age. Peer eligibility is denied until Task6. GET/POST /v1/me/verification and POST /v1/me/verification/skip return typed status/offerSeen/availability/private decline reason. Submit requires explicit true consent and processed owned front/back assets; live adapter is unavailable until Task8. Nullable required reason and optional back/visibility fields are generated with precise scalar guards; optional null inputs are omitted. No DOB, raw documents or private object URL is exposed.
