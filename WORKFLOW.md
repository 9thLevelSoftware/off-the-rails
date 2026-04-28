---
tracker:
  kind: linear
  endpoint: https://api.linear.app/graphql
  api_key: "$LINEAR_API_KEY"
  project_slug: "$LINEAR_PROJECT_SLUG"
  active_states:
    - Todo
    - In Progress
    - Rework
    - Merging
  terminal_states:
    - Done
    - Closed
    - Cancelled
    - Canceled
    - Duplicate
polling:
  interval_ms: 30000
workspace:
  root: ~/code/off-the-rails-symphony-workspaces
hooks:
  timeout_ms: 120000
  after_create: |
    git clone https://github.com/9thLevelSoftware/off-the-rails.git .
  before_run: |
    git fetch origin
agent:
  max_concurrent_agents: 3
  max_turns: 20
  max_retry_backoff_ms: 300000
  max_concurrent_agents_by_state:
    merging: 1
codex:
  command: >-
    codex --config shell_environment_policy.inherit=all --config model="gpt-5.5" --config model_reasoning_effort=xhigh app-server
  approval_policy: never
  thread_sandbox: workspace-write
  turn_sandbox_policy:
    type: workspaceWrite
    writableRoots:
      - ~/code/off-the-rails-symphony-workspaces
    readOnlyAccess:
      type: fullAccess
    networkAccess: true
    excludeTmpdirEnvVar: false
    excludeSlashTmp: false
  turn_timeout_ms: 3600000
  read_timeout_ms: 5000
  stall_timeout_ms: 300000
---
You are working on Linear ticket `{{ issue.identifier }}` for Off The Rails.

{% if attempt %}
Continuation context:
- This is retry attempt #{{ attempt }}.
- Resume from the current workspace state instead of restarting investigation from scratch.
{% endif %}

Issue context:
- Identifier: {{ issue.identifier }}
- Title: {{ issue.title }}
- Current status: {{ issue.state }}
- Labels: {{ issue.labels }}
- URL: {{ issue.url }}

Description:
{% if issue.description %}
{{ issue.description }}
{% else %}
No description provided.
{% endif %}

Instructions:
1. Work only in the provided per-ticket workspace.
2. Start by reading `AGENTS.md`, `.planning/STATE.md`, and any docs directly relevant to the ticket.
3. Maintain one persistent `## Codex Workpad` Linear comment with plan, acceptance criteria, validation, notes, and blockers.
4. Move `Todo` tickets to `In Progress` before implementation. Move completed validated work to `Human Review`.
5. Use `linear_graphql` when available for Linear reads/writes. Use `gh` for GitHub operations when available.
6. Run targeted tests during implementation and the relevant full validation before handoff.
7. If app behavior changes, include a concrete runtime/manual QA path in the workpad validation.
8. If blocked by missing auth, tools, or secrets, record the exact blocker and stop.
