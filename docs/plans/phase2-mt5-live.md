# Plan: Phase 2, MT5 live (awaiting user approval)

Status: Revised after Codex review F1 to F4 (see `docs/reviews/2026-11-19-phase2-mt5-plan.md`). Awaiting user approval. No code written. Decisions used: D1 to D8 (`docs/decisions.md`).

## Goal

Two real MT5 accounts show correct balance, equity, positions and P&L in the app. One going offline is flagged and does not affect the other. Read-only throughout.

## Slices (each needs its own go-ahead, in this order)

### 2A. Spike (throwaway, no app changes)
Question: does the firm's MT5 server accept the investor password through the Python `MetaTrader5` package, and can several terminals run side by side?
- New `backend/spikes/mt5_probe.py` (not imported by the app). Takes server, login and investor password from env vars or a prompt, never from files in the repo, never printed.
- Calls `initialize(path=<portable terminal>, login, password, server)`, then reads `account_info`, `positions_get`, `orders_get`, `history_deals_get`. Prints only counts and field names, not the password.
- Then run two terminals in two portable installs and check both stay logged in over several hours.
- Also check each firm's terms for third-party read-only monitoring (The5ers, XM, BlackBull, NYS Markets, GoFundTrade).
- Output: a short findings note in `docs/decisions.md`. If it fails, the design changes (for example an EA reporter), so we stop and re-plan.
- Needs from you: a Windows machine with MT5 installed per account, one account to start, its investor password entered by you on that machine.

### 2B. Persistence and credential vault
- PostgreSQL via SQLAlchemy 2 (async) + Alembic. Tables: `users`, `accounts` (with `user_id`), `account_credentials`, `positions`, `pending_orders`, `deals`, `account_snapshots`, `sync_status`. Source IDs (`platform*Id`) and `originalSymbol` kept on every row.
- Vault: investor passwords encrypted at rest (Fernet or AES-GCM) with a key from an environment variable, never stored in the DB or repo. Decrypted only inside the worker process. Excluded from API responses, logs and `repr`.
- Ownership: `accounts.user_id` is NOT NULL; every child table (`positions`, `pending_orders`, `deals`, `account_snapshots`, `sync_status`, `account_credentials`) carries `account_id` and uses a composite FK `(account_id, user_id)` so a row cannot reference another owner's account. All reads and writes go through owner-scoped repository methods that require `user_id`; routes never fetch global lists and filter afterwards.
- Idempotency keys (per account): `deals` unique on `(account_id, platform_deal_id)`; `positions` unique on `(account_id, platform_position_id, opened_at)` so a reused position ID is a new row; `pending_orders` unique on `(account_id, platform_order_id)`. Events (`position_opened`, `position_closed`, `deal_added`) live in a `position_events` table unique on `(account_id, event_type, platform_id, platform_time)`, inserted with `ON CONFLICT DO NOTHING`.
- Vault: pick AES-256-GCM (authenticated). Each ciphertext stores a `key_id`. Keys come from a secret file or env var kept outside DB backups and the repo; the server fails closed at startup if the active key is missing or cannot decrypt a canary record. Rotation: add a new key, re-encrypt rows in a one-off script, retire the old key. Secrets are wrapped in a `SecretStr`-style type, and exception handlers and the logging filter redact them. Request-body logging is disabled on auth and account routes. TLS terminates at a reverse proxy on the server host; the app refuses non-HTTPS base URLs outside debug builds.
- Tests: round-trip encryption, no credential field in any API schema, log capture (app, access, exception) contains no secret, missing key aborts startup, rotated key still decrypts old rows via `key_id`, cross-owner FK insert is rejected.
- Run `/security-review` on this slice.

### 2C. MT5 worker and connector
- `backend/app/connectors/mt5/`: `MT5Connector(ReadOnlyConnector)` talks to a per-account worker process (one portable terminal each), because the `MetaTrader5` package allows one login per process.
- Worker polls every 2 to 5 s, normalizes into `models/domain.py`, writes snapshots plus `last_update_at`.
- Field mapping (authoritative, never recomputed): `account_info.balance` -> `balance`, `.equity` -> `equity`, `.profit` -> floating P&L, `.margin` -> `margin`, `.margin_free` -> `freeMargin`, `.margin_level` -> `marginLevel`, `.currency` -> `currency`. Position P&L comes from each position's `profit`. Totals are never derived from summing positions.
- Snapshot atomicity: one poll = one DB transaction (account info + positions + orders + new deals). If any call fails or returns None, the transaction is not committed, the last complete snapshot is kept, `sync_status` records `last_error` and `last_attempt_at`, and freshness is computed from `last_success_at` only, so a partial poll can never look live.
- Deals sync incrementally from a stored watermark (`last_deal_time`, with a small overlap window deduped by the unique key), never a full history rescan per poll. DB writes are bounded by a per-process worker pool.
- Connection states and reconnect: after a reconnect take a fresh snapshot and reconcile open positions against stored rows by `(platformPositionId, opened_at)`; opens/closes are emitted only for real transitions and inserted idempotently (see 2B keys). Partial closes arrive as deals, not new positions. Existing freshness rule stays (`CONNECTED` with no data for 30s becomes `DELAYED`).
- Swap in at `core/deps.py` behind a setting (`CONNECTOR=mock|mt5`) so the mock keeps working for tests and demos.
- Tests with a fake MT5 module (no terminal needed): normalization, reported equity kept when it disagrees with position sums, failed/partial poll keeps last snapshot and goes DELAYED, reconcile after reconnect, worker restart, overlapping polls, replayed deals and position-ID reuse create no duplicates, one account failing leaves the other live, the connector has no write methods (existing invariant tests still pass).

### 2D. Auth and add-account flow
- Email + password sign-in (D2): argon2 hashing, short-lived access token (15 min), refresh token (30 days). Refresh tokens are stored only as hashes, rotated on every use, with reuse detection (a reused token revokes the whole token family); logout and password change revoke the family. Ownership is enforced by the owner-scoped repositories from 2B, not by per-route filtering. Removing an account deletes its credentials immediately and, by default, its history too (confirm with the user in the UI). Tests: for every data endpoint, user A gets 404 for user B's account and no B data in lists, summary or exposure; refresh reuse is rejected.
- API stays GET-only for data. The only non-GET routes are auth and account management (add/remove a monitored account). **This changes the existing "API is GET-only" test**; I will narrow it to "no trading routes" and say so explicitly in the diff. Needs your approval as part of this plan.
- App: login screen, add-account form (server, login, investor password, label), replacing the "Coming in Phase 2" message. The password is sent once over TLS, never stored in the app.
- API shape changes, so regenerate `mobile/test/fixtures/api_snapshot.json` and update Dart models together.

### 2E. Second account and offline test
- Add a second real account, kill its terminal, confirm it is flagged and the first stays live. Record results.

## Risks
- The investor password may be refused by some firm servers. 2A answers this before anything else is built.
- A firm may forbid third-party monitoring. Check terms first.
- Several terminals on one VPS use real RAM and CPU. 2A measures it.
- Windows-only `MetaTrader5` package means the worker cannot run on this repo's Linux CI or a Mac. Tests use a fake module.
- AlphaFunded (TradeLocker) is not covered here. It is Phase 5.

## Out of scope
Alerts, WebSockets, funded-account rules, TradeLocker, cTrader, real FX rates.

## Needs from you
1. Approve this plan (or edit it), including the GET-only test change in 2D.
2. For 2A: which machine runs the terminals, which one account first, and you entering its investor password yourself.
