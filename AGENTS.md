# Agent Context Contract

This file defines the repository-specific context contract. It supplements, but does not replace, higher-priority user and system instructions.

## Mandatory Reading Order

Before changing project code, plans, or project-level context, read:

1. `AGENTS.md`
2. [NorthStar.md](NorthStar.md)
3. [PROJECT_STATE.md](PROJECT_STATE.md)
4. The active plan linked by `PROJECT_STATE.md`
5. [DECISIONS.md](DECISIONS.md)
6. [LessonsLearned.md](LessonsLearned.md)
7. [README.md](README.md) or task-specific evidence only as needed

## Document Ownership

- `NorthStar.md` owns the stable overall objective and changes only when that objective changes.
- `PROJECT_STATE.md` owns current project truth: active milestone, definition of done, verified state, blockers, ownership, deferred work, and next action. Replace stale state instead of accumulating history.
- `DECISIONS.md` owns consequential decisions, rationale, evidence, and reopen conditions. Keep superseded decisions, mark them superseded, and link their replacements.
- `LessonsLearned.md` owns concise experiment history. Link resulting decisions without duplicating their rationale.
- The active plan linked by `PROJECT_STATE.md` is the current implementation contract. It does not silently replace a formal gate plan.
- `README.md` owns stable setup, usage, and architectural orientation; it is not the authority for current milestone status.

If project context conflicts with code or saved evidence, report the conflict to the coordinating agent or user. Do not silently reconcile it.

## Coordination Rules

- The coordinating agent owns milestone alignment, integration, and project-level context changes.
- Supporting agents may not redefine the milestone or edit project-level context concurrently. They return proposed context updates to the coordinating agent.
- Each supporting task must identify its bounded question, approved files, expected result, completion condition, assumptions, unresolved issues, and integration point.
- Preserve user changes and the dirty working tree. Do not move, archive, delete, or overwrite historical material without explicit authorization.
- Keep formal G6 freeze and formal G8 detection semantics separate from diagnostic studies unless a reviewed decision explicitly changes that boundary.

## Maintenance Rules

- Base current-state claims on code and saved evidence, not on README summaries alone.
- Update `PROJECT_STATE.md` after a milestone change, consequential finding, blocker change, or integrated supporting-agent result.
- Add a decision only for a consequential settled choice; add a lesson only for an experiment with a durable result.
- Keep one active milestone plan. Preserve formal gate plans and archive a superseded active plan only after approval.
- Keep evidence paths specific and verify they exist before linking them as support.
