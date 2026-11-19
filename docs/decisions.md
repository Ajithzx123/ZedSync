# Decisions

Record important technical and architectural decisions. Newest last. Format: what, why, consequences. Do not record a decision the user has not made.

## Made (already reflected in code and README)

### 1. Read-only by design
The system never places, modifies or cancels trades. The API exposes only GET routes and `ReadOnlyConnector` has only `fetch_*` methods; tests fail if either changes. Reason: monitoring product, and broker/prop-firm terms. Consequence: any future write capability needs an explicit user decision and a change to these tests.

### 2. Platform-reported values are authoritative
Balance, equity and floating P&L come from the platform and are never recomputed. Realized P&L is computed from deals, excluding deposits and withdrawals.

### 3. Never hide gaps or stale data
Disconnected accounts stay visible with last-known values and the summary is flagged `isComplete: false`. A `CONNECTED` account with no data for 30s is reported `DELAYED`.

### 4. Currency handling
Totals convert to a chosen base currency and report the FX rates used with timestamps; mixed-currency groups are never summed raw. Rates are static for now (`static-phase1`); live rates are planned.

### 5. Normalized models keep source identity
Every record keeps its `platform*Id` and `originalSymbol`. Partial closes remain separate deals; trades are not synthesized.

### 6. Connector abstraction with a mock first
Backend depends on `ReadOnlyConnector`; `MockConnector` stands in until real platforms exist. The swap point is `backend/app/core/deps.py`.

### 7. Stack
Backend: FastAPI + pydantic v2 + pytest. Mobile: Flutter with GetX (state/DI) and layered `data/domain/ui` folders. Do not migrate state management unless asked.

### 8. Polling for now
The app polls every 5s. WebSockets are planned (Phase 3) behind the same controller.

### 9. Workflow
Claude plans and implements; Codex reviews read-only; the user approves plans and every commit/push/merge. See `AGENTS.md`.

### 10. Claude and Codex communicate through shared repo files
Handoff state in `docs/handoffs/latest.md`; one immutable-findings review report per feature in `docs/reviews/`, with Claude's resolutions in a separate section. Claude owns project docs; Codex owns review reports. Codex's read-only status is instruction-based for now; sandbox enforcement may be configured separately. Reason: no re-explaining history each session, and an auditable review trail.

### D1 to D6, D8. Roadmap defaults accepted (user said "use defaults", 2026-11-19)

| # | Decision | Chosen |
|---|---|---|
| D1 | First user | The owner only; data model stays multi-user-ready (user id on owned records) |
| D2 | App sign-in | Email + password first; Google/Apple later |
| D3 | Backend hosting | One Windows VPS running the MT5 worker and API together; split later |
| D4 | Database | PostgreSQL on the same VPS; managed later |
| D5 | Push notifications | Firebase (user creates the project, Claude wires it) |
| D6 | Base currency default | USD |
| D8 | App name | Keep "ZedSync Trading Hub" for now |

Consequences: Phase 2 plan assumes a Windows VPS (MT5 needs Windows), local Postgres, and email/password auth with server-side credential encryption. Nothing is implemented yet.

### D7. First brokers / prop firms (user answer, 2026-11-19)

The5ers, XM, BlackBull, NYS Markets (nysmarkets.com), GoFundTrade: all on MT5. AlphaFunded: on TradeLocker.

Consequences: Phase 2 (MT5) covers five of the six firms. AlphaFunded needs the TradeLocker connector, which waits for its own roadmap phase. Server names, account types and investor-password support per firm are not yet verified.

## Open

None. D1 to D8 are all decided.
