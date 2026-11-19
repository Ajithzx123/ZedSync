# Code reviews

Persistent review reports written by Codex (independent, read-only reviewer) and answered by Claude (implementer). Rules and roles are in `AGENTS.md`; this file is the short version of the review loop.

## Files

- One report per significant feature or phase: `YYYY-MM-DD-<feature>.md`, copied from `review-template.md`.
- Never overwrite an earlier report. A re-review of the same feature goes in a new "Round N" section of that report.
- Live state of the current review is tracked in `docs/handoffs/latest.md`.

## Ownership

| Part of the report | Who writes it |
|---|---|
| Header, requirements, findings, areas reviewed, Codex tests, verdict | **Codex** only |
| `Claude resolution` section (and the resolution cell of each finding) | **Claude** only, appended; never edits Codex's original text |

Original findings are **immutable**. Claude does not reword, delete, or re-rate them. Disagreement is written in the resolution section.

## Loop

1. **Claude** finishes the implementation, runs tests, and updates `docs/handoffs/latest.md` (next agent: Codex).
2. **Codex** reads the handoff, then reviews the **actual code and `git diff` / `git status`** (including untracked files), not Claude's summary. It writes a new report from the template and updates the handoff (next agent: Claude).
3. **Claude** reads the report and evaluates each finding: fixes valid ones, or rejects with reasoning. It records the outcome in the `Claude resolution` section, re-runs tests, and updates the handoff (next agent: Codex).
4. **Codex** reads the resolutions and the new diff, adds a "Final review" section, and sets the verdict to `Approved` or `Changes requested`, then updates the handoff.
5. **Claude** updates `docs/current_status.md` at the end of the significant task.

Codex must not edit application source, tests, config, dependencies, or git state. If Codex finds that `docs/current_status.md` is wrong, it reports the discrepancy in its report; Claude fixes the document.

## Severity and status values

- Severity: `Blocker` (must fix), `Major`, `Minor`, `Nit`.
- Resolution: `Fixed`, `Rejected` (with reasoning), `Deferred` (with where it is tracked), `Needs user decision`.
- Report status: `Review requested`, `Findings reported`, `Resolved, awaiting final review`, `Approved`, `Changes requested`.
