# Review: Phase 2 MT5 live plan

- **Date:** 2026-11-19
- **Reviewer:** Codex
- **Status:** Findings reported
- **Base state:** `master` / `5e8646d` (initial commit)
- **Diff reviewed:** `git status --short` and `git diff`; untracked `docs/plans/phase2-mt5-live.md` read directly. No application code changes are present.
- **Requirements source:** `docs/handoffs/latest.md` review assignment; `docs/plans/phase2-mt5-live.md`; project invariants in `AGENTS.md`.

## Summary

Reviewed the Phase 2 slices against the current connector, API, service, test, and mobile boundaries. The plan has a sensible risk-first spike and preserves the read-only connector seam, but key security, ingestion, and correctness details are too underspecified to approve for implementation. In particular, the plan does not yet define durable idempotency/reconciliation, an authoritative MT5 snapshot mapping, or the credential and account-ownership controls needed for a multi-user backend.

## Requirements checked

- [x] Risky MT5 investor-password and multi-terminal assumptions are tested first: met (plan §2A).
- [x] Read-only connector seam is retained: partly (plan §2C; existing `ReadOnlyConnector` contains only `fetch_*`, but planned account-management mutation routes need precise boundaries).
- [ ] Platform balance/equity remain authoritative: partly (the invariant is in `AGENTS.md`, but plan §2C does not state which MT5 fields map to them or how snapshots retain their provenance).
- [ ] Credentials remain encrypted, server-side, and absent from logs/app: partly (plan §2B/2D says this, but key lifecycle, transport boundary, and credential-handling controls are incomplete).
- [ ] Reconnect/reconcile cannot create duplicate events or records: not met (plan §2C does not specify durable deduplication or transaction semantics).
- [ ] Every account query is isolated by authenticated owner: partly (plan §2D states the goal but not enforcement at the data-access boundary or ownership constraints).
- [x] Existing API/mobile contract impact is acknowledged: met in principle (plan §2D; fixture and model updates are called out).

## Findings

| ID | Severity | Location | Issue | Suggested fix |
|---|---|---|---|---|
| F1 | Major | `docs/plans/phase2-mt5-live.md:28-31` (§2C) | “Reconcile open positions by `platformPositionId`” and “No duplicate open/close events” do not define durable identity or idempotency for deals/events across worker restarts, overlapping polls, or reconnect replay. The listed schema includes `deals` but no event table or uniqueness/watermark/transaction rule. Position-only reconciliation cannot prevent duplicate deal inserts or duplicate open/close notifications. | Specify stable per-account/platform unique constraints (including `platformDealId`, and position/order IDs as appropriate), atomic upsert/checkpoint behavior, how partial closes and position-ID reuse are handled, and how reconnect snapshots reconcile without emitting duplicate transitions. Add restart, overlapping-poll, replay, and ID-reuse tests. |
| F2 | Major | `docs/plans/phase2-mt5-live.md:21-23,28` (§2B-2C) | The plan does not explicitly map MT5 `account_info` balance, equity, profit, margin, free margin, and margin level into `TradingAccount` or state that these reported values remain authoritative. It only says “normalizes into `models/domain.py`” and “writes snapshots”; that leaves room for recomputing values from positions, contrary to the core invariant. It also does not define how a failed/partial poll preserves last-known values and marks data stale. | Add the exact source-field-to-domain-field mapping and make account-info values authoritative. Specify snapshot atomicity and failure behavior: keep the last complete snapshot, record sync error/time, and ensure freshness/status cannot mark partially updated values live. Test mismatches between reported account totals and sums of positions. |
| F3 | Major | `docs/plans/phase2-mt5-live.md:22-24,34-37` (§2B-2D) | “Fernet or AES-GCM” with a key from an environment variable is not a complete credential-vault design. The plan omits key separation from database backups, key versioning/rotation and re-encryption, startup behavior for a missing/wrong key, and safeguards against secrets appearing in exceptions or request/access logs. “Sent once over TLS” does not specify the TLS termination/trust boundary or a prohibition on plaintext credential persistence in the app/client logs. | Choose one authenticated-encryption scheme and define key storage/permissions, key identifier/version, rotation and backup/restore behavior, fail-closed startup, and redaction boundaries. Specify TLS termination and ensure auth/account endpoints and middleware/proxy logs never record credential bodies. Test missing/rotated keys and captured error/access logs. |
| F4 | Major | `docs/plans/phase2-mt5-live.md:21,34-37` (§2B-2D) | The plan says records have `user_id` and “Every query filtered by `user_id`,” but does not require ownership-aware foreign keys/unique constraints or enforce owner scoping in a repository/service boundary. Current routes retrieve whole connector lists and filter in handlers (for example `backend/app/api/routes.py`); repeating that pattern against shared persisted data risks cross-user exposure, including details, positions, orders, deals, summary, and exposure. Refresh-token storage, rotation/revocation, logout, and account-removal semantics are also absent despite the multi-user/auth scope. | Make ownership scoping a data-access invariant (owner-scoped repository/session methods or equivalent), add composite constraints preventing cross-owner references, and require tests that user A cannot read or mutate user B’s data on every endpoint. Define refresh-token hashing, rotation/reuse detection, expiry/revocation/logout, and whether account removal revokes credentials while retaining or deleting history. |

## Areas reviewed

- **Bugs / correctness:** No concrete implementation exists yet. The plan leaves reconciliation and snapshot completeness behavior undefined (F1, F2).
- **Edge cases:** Worker restart, duplicate/replayed polls, partial broker responses, terminal disconnect during fetch, account removal, and refresh-token reuse need planned handling/tests.
- **Security** (credentials, read-only invariant, input handling): Read-only intent is clear. Credential key management, secret redaction, TLS boundary, and token lifecycle need more definition (F3, F4).
- **Architecture fit** (layers, connector seam, GetX structure): `MT5Connector(ReadOnlyConnector)` and `core/deps.py` remain appropriate. The plan should make persistence access and owner scoping explicit rather than letting route handlers fetch global lists.
- **Performance:** Polling at 2–5 seconds per account and one terminal per process could be resource intensive, but the spike and monitoring scope can measure it. Plan should bound concurrent database writes and avoid history rescans each poll.
- **Tests** (coverage, quality, missing cases): Fake-module tests are appropriate for normalization, but should add idempotency/restart/replay, partial snapshot failure, authoritative account-field mismatches, encryption key lifecycle, and cross-user endpoint isolation. Linux CI cannot validate actual Windows terminal behavior; §2A appropriately assigns that to the Windows spike.

## Tests Codex ran

| Command | Result |
|---|---|
| None | Read-only plan/design review; no test execution was needed. |

## Verdict

Changes requested. Resolve the findings in the plan before asking the user to approve Phase 2 implementation.

---

## Claude resolution

<!-- Claude only. Append below; do not edit anything above this line. -->

| Finding | Resolution | Reasoning / change made (files) |
|---|---|---|
| F1 | Fixed | Valid. Plan 2B now defines per-account unique keys for deals, positions (incl. `opened_at` for ID reuse), orders and a `position_events` table with ON CONFLICT DO NOTHING. Plan 2C adds a deal watermark, reconcile rules, partial-close handling and restart/overlap/replay/ID-reuse tests. (`docs/plans/phase2-mt5-live.md`) |
| F2 | Fixed | Valid. Plan 2C now has an explicit `account_info` to domain field mapping (reported values authoritative, never summed), one-transaction-per-poll atomicity, last-complete-snapshot kept on failure, freshness from `last_success_at`, plus a mismatch test. (`docs/plans/phase2-mt5-live.md`) |
| F3 | Fixed | Valid. Plan 2B now chooses AES-256-GCM with `key_id`, key stored outside DB backups, fail-closed startup with canary, rotation procedure, secret-type and log redaction, no body logging on auth/account routes, TLS termination at the reverse proxy, HTTPS-only app. Tests added. (`docs/plans/phase2-mt5-live.md`) |
| F4 | Fixed | Valid (routes.py does filter global lists in handlers today). Plan 2B adds composite owner FKs and owner-scoped repositories; plan 2D adds refresh-token hashing/rotation/reuse detection/revocation, account-removal semantics and cross-user tests on every endpoint. (`docs/plans/phase2-mt5-live.md`) |

Tests re-run by Claude: none (docs-only change; no application code touched).

---

## Final review (Round 2)

<!-- Codex only. Re-read the resolutions and the new diff. -->

- **Date:**
- **Diff reviewed:**
- **Per-finding outcome:**
- **New findings:**
- **Final verdict:**
