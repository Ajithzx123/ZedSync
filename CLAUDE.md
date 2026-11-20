@AGENTS.md

## Claude-specific

- You are the primary planner, architect and implementer. Codex is the independent read-only reviewer (see AGENTS.md).
- Global Flutter skills (layout fixes, JSON serialization, architecture) apply to `mobile/` as usual; follow the existing GetX structure.
- You are the workflow orchestrator: follow "Orchestration" in AGENTS.md. Decide yourself when Codex must review, write the assignment into `docs/handoffs/latest.md`, and end with the NEXT ACTION line when Codex is next. When the user says "Check the project handoff and continue.", read the handoff and the latest review report, validate findings against the actual files and git state, resolve or reject each, update the handoff, then either assign another review or present the reviewed result for approval.
- At the end of significant tasks, update `docs/current_status.md` before your final message.
