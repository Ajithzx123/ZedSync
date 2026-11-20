# Current status

Last updated: 2026-11-19 (AI workflow setup session). Update at the end of every significant task.

## Summary

Phase 0 + 1 complete: FastAPI backend with a mock connector and a Flutter/GetX app reading it. No real broker connections. Initial commit `5e8646d` made 2026-11-19.

## Baseline (verified 2026-11-19)

| Check | Result |
|---|---|
| `backend`: `python -m pytest` | 16 passed |
| `mobile`: `flutter test` | 10 passed |
| `mobile`: `flutter analyze` | 1 info: `prefer_initializing_formals` at `lib/data/repositories/portfolio_repository.dart:29`. No errors or warnings. |

## Completed

- Backend: GET-only API, normalized domain models, `ReadOnlyConnector` contract, mock connector (6 fictional accounts), portfolio summary/exposure, static FX, freshness rule.
- Mobile: Home, Accounts (+ detail), Positions, Analytics (exposure only), More (history, settings), polling controller, JSON parsing tests.
- AI workflow docs: `AGENTS.md`, `CLAUDE.md`, `docs/` including the review mechanism (`docs/reviews/`, `docs/handoffs/latest.md`) (2026-11-19).

## In progress

Phase 2 plan in `docs/plans/phase2-mt5-live.md`: Codex plan review done (F1 to F4 all fixed, see `docs/reviews/2026-11-19-phase2-mt5-plan.md`) and the user APPROVED the plan on 2026-11-19, including narrowing the GET-only test to "no trading routes" in 2D. State `APPROVED_FOR_IMPLEMENTATION` for slice 2A only; each later slice needs its own go-ahead. No Phase 2 code written.

## Pending

See `ROADMAP.md` phases 2 to 8. Next up is Phase 2 (MT5 live): spike with one real account, PostgreSQL, credential vault, MT5 worker, auth, add-account flow.

## Open decisions

All of D1 to D8 are decided as of 2026-11-19 (see `docs/decisions.md`). D7: MT5 on The5ers, XM, BlackBull, NYS Markets, GoFundTrade; TradeLocker on AlphaFunded.

## Known issues

- No persistence; state is in memory and settings reset on restart.
- No authentication on the API; CORS allows any origin (GET only).
- Polling every 5s instead of streaming.
- FX rates are static.
- No widget tests in the app.
- One analyzer info (see baseline).
- `mobile/README.md` and `pubspec.yaml` description are still Flutter template text.

## Awaiting user

- Nothing on the plan (approved). Slice 2B onward each need a go-ahead after 2A results.
- For 2A: which Windows machine runs the terminals, which one MT5 account first, and confirmation it has an investor password (entered by the user, never shared).

## Next recommended step

1. Initial commit done (5e8646d, 2026-11-19). Docs changes since then are uncommitted.
1a. Plan reviewed by Codex, resolved and approved (done 2026-11-19).
2. Slice 2A: Claude writes `backend/spikes/mt5_probe.py` once the user names the machine and account.
3. User runs the MT5 spike on a real account (investor password only).

## Review state

No pending Codex review or open findings. Reports live in `docs/reviews/`; the live handoff between Claude and Codex is `docs/handoffs/latest.md` (currently: plan approved, next agent Claude for slice 2A).
