# Current status

Last updated: 2026-11-19 (AI workflow setup session). Update at the end of every significant task.

## Summary

Phase 0 + 1 complete: FastAPI backend with a mock connector and a Flutter/GetX app reading it. No real broker connections. Git repo has **no commits yet**; everything is untracked.

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

Nothing.

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
- No commits yet; `.claude/launch.json` is untracked.

## Awaiting user

- Approval for the initial commit.
- Which one MT5 account to use for the spike, and confirmation it has an investor password.

## Next recommended step

1. User approves an initial commit.
2. Run `/plan-eng-review` on Phase 2 and write the plan for approval before any MT5 code.
3. User runs the MT5 spike on a real account (investor password only).

## Review state

No pending Codex review or open findings. Reports live in `docs/reviews/`; the live handoff between Claude and Codex is `docs/handoffs/latest.md` (currently: no active task, next agent Claude).
