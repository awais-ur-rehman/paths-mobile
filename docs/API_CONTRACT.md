# Foundation API contract

Pinned contract1.0.0 is copied from the backend's real Nest OpenAPI export. Run `python3 tools/generate_api_contract.py`, then `dart format lib/core/network/generated/api_contract.dart`. The scalar DTO generator fails on unsupported shapes instead of silently omitting fields. Generated DTOs carry the source SHA256; never edit them manually. Extend the generator with meaningful cases when the API adds optional/nested models.

ApiClient uses one Dio transport per origin, bounded timeouts, typed transport/contract/cancellation failures and disposable cancellation tokens supplied by the route owner. No response bodies, tokens or coordinates are logged. AppBootstrap performs no I/O in its constructor; a route explicitly invokes check. The private Phase0 harness remains the current entry until the auth task replaces it; its transport/keys remain separate from production API configuration. Auth redirects and single-flight refresh belong to Task3.
