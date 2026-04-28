# Execution Plans

Use this directory for complex or multi-step work that should survive context windows.

## Layout

- `active/` - current plans with progress and decision notes.
- `completed/` - finished plans retained for historical context.

## Rules

- Small one-turn changes do not need an execution plan.
- Complex plans should include goal, acceptance criteria, implementation outline, validation, and decision log.
- Move completed plans out of `active/` in the same change that finishes the work.
