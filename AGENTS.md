# AGENTS.md: ZedSync Trading Hub

Shared instructions for every AI agent working in this repo (Claude, Codex). Keep it short; details live in `docs/`.

## Project

Read-only, multi-account trading monitor: one mobile app showing MT5, TradeLocker and cTrader accounts together. Current state: Phase 0 + 1 (mock connector only; no real broker connections). See `README.md` (run/test), `ROADMAP.md` (phases, open decisions D1 to D8, risks).

- `backend/`: Python, FastAPI, pydantic v2, pytest. Layers: `api/` -> `services/` -> `connectors/` (`ReadOnlyConnector`), `models/domain.py`, wiring in `core/deps.py`.
- `mobile/`: Flutter, GetX, http, intl. Layers: `lib/data` (services, repositories), `lib/domain/models`, `lib/ui` (features, core), wiring in `lib/app_bindings.dart`.

## Roles

- **Claude: primary planner, architect and implementer.** Understands the project, writes plans, implements approved plans, runs tests, fixes review findings, maintains `docs/`.
- **Codex: independent senior code reviewer. Read-only with respect to the project.** Must not modify application source, tests, config or dependencies, run formatters that write, install packages, or change git state. It reports findings; it does not fix them. Its only permitted writes are: new review reports in `docs/reviews/`, and `docs/handoffs/latest.md` when it is the acting agent handing over. (Enforced by instruction only for now; Codex's sandbox read-only mode may be configured separately.)

### File ownership

| Files | Owner / who may edit |
|---|---|
| `AGENTS.md`, `CLAUDE.md`, `docs/architecture.md`, `docs/decisions.md`, `docs/current_status.md` | **Claude** only. Codex reports discrepancies in its review report instead of rewriting these. |
| `docs/reviews/<report>.md` | **Codex** creates it and owns the original findings (immutable). **Claude** may only add notes in the `Claude resolution` section. |
| `docs/reviews/README.md`, `docs/reviews/review-template.md` | Claude (Codex copies the template, never edits it) |
| `docs/handoffs/latest.md` | Either agent, but **only the agent currently acting**, when handing work over |
| Application source (`backend/`, `mobile/`), tests, config | Claude only, within an approved plan |

## Before substantial work (both agents)

1. Read `docs/current_status.md`, then `docs/handoffs/latest.md`, then `docs/architecture.md`, and `docs/decisions.md` and `ROADMAP.md` where relevant.
2. Inspect the actual code you will touch. Do not rely on docs or summaries alone.
3. Run `git status` and `git diff` so you know what is already changed.

## Workflow

1. **Plan (Claude).** For any significant feature (new connector, persistence, auth, API shape change, new screen, anything touching the invariants below), write a plan: goal, files to change, approach, tests, risks. Small fixes need no plan. Claude then assigns Codex a plan review (see "Orchestration"), resolves the findings, and only then asks the user for approval. **Never present an unreviewed plan as awaiting approval when it needs review.** Codex review is not user approval.
2. **Implement (Claude).** Follow the approved plan only. Run the relevant tests. Do not touch unrelated files. Then update `docs/handoffs/latest.md` (next agent: Codex) with the files changed and tests run.
3. **Review (Codex, assigned by Claude automatically when the trigger list below applies; the user need not ask).** Codex reviews against the requirements, the **actual files and the actual `git diff` / `git status`** (including untracked files), not Claude's summary. It checks: requirements met, bugs, edge cases, security, architecture fit, performance, and test quality. It writes a new report in `docs/reviews/` from `review-template.md`, with findings ranked by severity and file:line references, then updates the handoff (next agent: Claude). Codex may run read-only commands (tests, analyzer, `git diff`, `git log`).
4. **Triage (Claude).** Read the report. For each finding: fix it if valid, or reject it with reasoning. Never silently ignore one. Record each outcome in the report's `Claude resolution` section without altering Codex's original text, re-run tests, and update the handoff (next agent: Codex).
5. **Final review (Codex, when Claude judges it warranted).** Codex re-reads the report and the updated diff, adds the final-review section and verdict (`Approved` / `Changes requested`), and updates the handoff.
6. **Wrap up (Claude).** Update `docs/current_status.md` (and `architecture.md` / `decisions.md` if they changed).

## Orchestration (Claude runs the workflow; the user only switches agents)

The user is the product owner. They operate the whole loop with two commands: to Claude, "Check the project handoff and continue."; to Codex, "Check the project handoff and continue your pending task." Everything else is Claude's job. Never ask the user to write a Codex prompt, copy a plan or findings between agents, create review tasks, or remember who is next. Do not interrupt them with procedural questions; ask only about product decisions, missing requirements, real trade-offs, or approval gates.

**Claude must automatically assign a Codex review for:** significant plans, specs, architecture, DB schemas and migrations, API contracts, security designs, multi-phase roadmaps, major refactors; UI/UX plans, wireframes, mockups, screenshots and navigation flows (list the image/file paths and tell Codex to open them, not just read text); significant implementations, complex bug fixes, auth, DB changes, financial logic, concurrency/background work, performance-sensitive and production-critical changes; and final verification of major features or after critical findings are resolved. Skip Codex for trivial changes (typos, formatting, low-risk doc edits).

**Order for anything needing both review and approval:** Claude prepares -> Claude assigns Codex review in the handoff -> Codex reviews -> Claude validates and resolves findings -> Claude presents the reviewed result -> user approves or requests changes. Review approval is not implementation approval; implementation approval is not release approval.

**Approval gates (user decides):** feature scope, product behavior, major architecture, significant trade-offs, API contract and DB changes, security-sensitive design, adding dependencies, destructive operations, commits/pushes, releases and deployment. Claude may resolve ordinary findings inside approved scope without asking.

**Review cycles:** no infinite loops. Minor findings Claude may fix safely without another Codex round. Request another round only for critical architecture or security, or an unresolved disagreement.

**Workflow states** (kept in the handoff, always matching reality): `PLANNING`, `WAITING_FOR_CODEX_PLAN_REVIEW`, `WAITING_FOR_CLAUDE_REVIEW_RESOLUTION`, `WAITING_FOR_USER_APPROVAL`, `APPROVED_FOR_IMPLEMENTATION`, `IMPLEMENTING`, `WAITING_FOR_CODEX_IMPLEMENTATION_REVIEW`, `RESOLVING_REVIEW_FINDINGS`, `WAITING_FOR_CODEX_FINAL_REVIEW`, `READY_FOR_USER_FINAL_APPROVAL`, `COMPLETED`, `BLOCKED`.

**Before every handoff, Claude:** reads the current handoff, inspects `git status`/`git diff`, reconciles any mismatch, updates the handoff (state, next agent, review assignment), and only then tells the user which agent to open. Never record an approval or a completed review unless it is explicitly recorded or the report exists and was checked. If the handoff is stale or contradictory, trust the repo, reconcile, and do not restart finished work.

**Ending a turn:** if Codex is next, the last thing Claude says is:

> **NEXT ACTION: Open Codex for this project and enter:** "Check the project handoff and continue your pending task."

If Claude is next, say to return to Claude with "Check the project handoff and continue." Always make clear what is done, what needs the user's decision, whether a Codex review is pending, and which agent is next. Keep it short.

**Codex, on starting:** read `AGENTS.md`, `docs/current_status.md`, `docs/handoffs/latest.md`; act only if the handoff names Codex as next. Do the assigned review in the handoff's "Review assignment" section: open every listed file and image yourself, verify claims instead of trusting Claude's summary, find problems, risks, omissions, inconsistencies and alternatives, propose fixes but do not implement them, never touch application code. Save the report in `docs/reviews/` from the template, then update the handoff (state, next agent: Claude, report path).

Review reports: one per significant feature or phase, named `YYYY-MM-DD-<feature>.md`; earlier reports are never overwritten (a re-review is a new "Round N" section). Original findings are immutable. See `docs/reviews/README.md`.

## Hard rules

- **No new dependency without the user's approval.**
- **No commit, push, merge, rebase, reset, branch deletion, or other destructive operation (deleting files/data, `git clean`, force anything) without the user's explicit approval.** Approval applies to that one action.
- Modify only files needed for the task. Never edit `.venv/`, `mobile/build/`, `mobile/.dart_tool/`, generated or lock files unless the task requires it.
- Never read, print, log, or commit secrets (`.env`, investor passwords, tokens, keys).
- Do not invent decisions. Open decisions D1 to D8 in `ROADMAP.md` stay open until the user answers; record the answer in `docs/decisions.md`.
- Do not invent architecture in docs. Document only what exists in code.
- Report test results honestly: what ran, what passed, what failed, what was skipped.

## Project invariants (do not break; tests enforce some)

- **Read-only.** No code path may place, modify or cancel trades. The API is GET-only; the connector contract has only `fetch_*` methods. Existing tests assert both; keep them.
- Platform-reported balance and equity are authoritative; never recompute them.
- Disconnected accounts stay visible with last-known values; summary is flagged `isComplete: false`. Stale data is never shown as live (`CONNECTED` with no data for 30s becomes `DELAYED`).
- No raw cross-currency sums; totals use a base currency and report the FX rates used.
- Keep source IDs (`platform*Id`) and `originalSymbol` on every record.
- Credentials stay on the server, encrypted; nothing secret goes in the Flutter app or logs.

## Commands (Windows, PowerShell)

```powershell
cd backend; .venv\Scripts\python -m pytest                              # backend tests
cd backend; .venv\Scripts\python -m uvicorn app.main:app --reload --port 8000
cd mobile; flutter test                                                 # app tests
cd mobile; flutter analyze
```

## Conventions

- Backend: type hints, pydantic models in `models/domain.py`, new platforms implement `ReadOnlyConnector` and are swapped in at `core/deps.py`. Add a pytest for every behaviour change.
- Mobile: keep GetX and the existing `data/domain/ui` layout; do not migrate state management. JSON models parse strictly (`json_utils.dart`).
- If the API shape changes, regenerate `mobile/test/fixtures/api_snapshot.json` from the backend and update the Dart models together.

## Handoff protocol (resuming in a new session)

Starting a session (Claude or Codex):
1. Read `AGENTS.md`, then `docs/current_status.md` (project state), then `docs/handoffs/latest.md` (who acts next and what).
2. Run `git status` and `git diff` to see uncommitted work; trust the code over the docs if they disagree, and note the mismatch (Claude fixes the doc; Codex reports it in its review report).
3. Act only if the handoff names you as the next agent; otherwise tell the user. Continue from "Next action" unless the user says otherwise.

Handing over (whichever agent is currently acting):
- Update `docs/handoffs/latest.md` (structure in the file itself) with: task, workflow state, current and next agent, whether Codex review and user approval are required, the review assignment, outstanding findings and decisions, files changed, git state, tests run, and the exact next action. Only the acting agent edits it. Update it BEFORE telling the user to switch agents.

Ending a significant task or session (Claude):
1. Update `docs/current_status.md`: completed, in progress (with files touched and what is left), pending, known issues, latest test results, next step, and any open review findings.
2. Note anything awaiting user approval (plans, commits, decisions).
3. Leave work uncommitted unless the user approved a commit.
