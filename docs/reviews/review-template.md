# Review: <feature or phase>

<!-- Copy to docs/reviews/YYYY-MM-DD-<feature>.md. Codex writes everything above the "Claude resolution" section. -->

- **Date:**
- **Reviewer:** Codex
- **Status:** Findings reported
- **Base state:** <branch / commit, or "no commits yet">
- **Diff reviewed:** <command used, e.g. `git diff`, `git status --short`, untracked files read directly>
- **Requirements source:** <plan, handoff, or user request that defines done>

## Summary

<2 to 4 sentences: what was reviewed and the overall assessment.>

## Requirements checked

- [ ] <requirement> : met / not met / partly (evidence: file:line)

## Findings

| ID | Severity | Location | Issue | Suggested fix |
|---|---|---|---|---|
| F1 | Blocker / Major / Minor / Nit | `path:line` | | |

## Areas reviewed

Note "no issues" explicitly where true.

- **Bugs / correctness:**
- **Edge cases:**
- **Security** (credentials, read-only invariant, input handling):
- **Architecture fit** (layers, connector seam, GetX structure):
- **Performance:**
- **Tests** (coverage, quality, missing cases):

## Tests Codex ran

| Command | Result |
|---|---|

## Verdict

<Changes requested / Approved with notes / Approved>

---

## Claude resolution

<!-- Claude only. Append below; do not edit anything above this line. -->

| Finding | Resolution | Reasoning / change made (files) |
|---|---|---|
| F1 | Fixed / Rejected / Deferred / Needs user decision | |

Tests re-run by Claude:

---

## Final review (Round 2)

<!-- Codex only. Re-read the resolutions and the new diff. -->

- **Date:**
- **Diff reviewed:**
- **Per-finding outcome:** F1: closed / still open (why)
- **New findings:**
- **Final verdict:** Approved / Changes requested
