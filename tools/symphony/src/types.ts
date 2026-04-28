export type IssueStateName = string;

export interface BlockerRef {
  id: string | null;
  identifier: string | null;
  state: string | null;
  created_at: string | null;
  updated_at: string | null;
}

export interface Issue {
  id: string;
  identifier: string;
  title: string;
  description: string | null;
  priority: number | null;
  state: IssueStateName;
  branch_name: string | null;
  url: string | null;
  labels: string[];
  blocked_by: BlockerRef[];
  created_at: string | null;
  updated_at: string | null;
}

export interface WorkflowDefinition {
  config: Record<string, unknown>;
  prompt_template: string;
  path: string;
}

export interface TrackerConfig {
  kind: 'linear';
  endpoint: string;
  api_key: string | null;
  project_slug: string | null;
  active_states: string[];
  terminal_states: string[];
}

export interface PollingConfig {
  interval_ms: number;
}

export interface WorkspaceHooks {
  after_create: string | null;
  before_run: string | null;
  after_run: string | null;
  before_remove: string | null;
  timeout_ms: number;
}

export interface WorkspaceConfig {
  root: string;
}

export interface AgentConfig {
  max_concurrent_agents: number;
  max_turns: number;
  max_retry_backoff_ms: number;
  max_concurrent_agents_by_state: Map<string, number>;
}

export interface CodexConfig {
  command: string;
  approval_policy: unknown;
  thread_sandbox: unknown;
  turn_sandbox_policy: unknown;
  turn_timeout_ms: number;
  read_timeout_ms: number;
  stall_timeout_ms: number;
  model: string | null;
  model_reasoning_effort: string | null;
}

export interface ServiceConfig {
  workflow_path: string;
  workflow_dir: string;
  tracker: TrackerConfig;
  polling: PollingConfig;
  workspace: WorkspaceConfig;
  hooks: WorkspaceHooks;
  agent: AgentConfig;
  codex: CodexConfig;
}

export interface WorkspaceRef {
  path: string;
  workspace_key: string;
  created_now: boolean;
}

export type RunStatus =
  | 'PreparingWorkspace'
  | 'BuildingPrompt'
  | 'LaunchingAgentProcess'
  | 'InitializingSession'
  | 'StreamingTurn'
  | 'Finishing'
  | 'Succeeded'
  | 'Failed'
  | 'TimedOut'
  | 'Stalled'
  | 'CanceledByReconciliation';

export interface RunAttempt {
  issue_id: string;
  issue_identifier: string;
  attempt: number | null;
  workspace_path: string;
  started_at: number;
  status: RunStatus;
  error?: string;
}

export interface LiveSession {
  session_id: string;
  thread_id: string;
  turn_id: string;
  codex_app_server_pid: string | null;
  last_codex_event: string | null;
  last_codex_timestamp: number | null;
  last_codex_message: string | null;
  codex_input_tokens: number;
  codex_output_tokens: number;
  codex_total_tokens: number;
  last_reported_input_tokens: number;
  last_reported_output_tokens: number;
  last_reported_total_tokens: number;
  turn_count: number;
}

export interface RetryEntry {
  issue_id: string;
  identifier: string;
  attempt: number;
  due_at_ms: number;
  error: string | null;
}

export interface Logger {
  info(event: string, fields?: Record<string, unknown>): void | Promise<void>;
  warn(event: string, fields?: Record<string, unknown>): void | Promise<void>;
  error(event: string, fields?: Record<string, unknown>): void | Promise<void>;
  debug(event: string, fields?: Record<string, unknown>): void | Promise<void>;
}

export interface AgentRunInput {
  issue: Issue;
  attempt: number | null;
  prompt: string;
  workspace: WorkspaceRef;
  config: ServiceConfig;
}

export interface AgentRunResult {
  status: 'succeeded' | 'failed' | 'timed_out' | 'stalled' | 'canceled';
  error?: string;
  live_session?: LiveSession;
}

export interface AgentRunner {
  run(input: AgentRunInput): Promise<AgentRunResult>;
  cancel?(issueId: string, reason: string): Promise<void>;
}

export interface IssueTracker {
  fetchCandidateIssues(activeStates: string[]): Promise<Issue[]>;
  fetchIssuesByIds(ids: string[]): Promise<Issue[]>;
  fetchTerminalIssues(terminalStates: string[]): Promise<Issue[]>;
}

export interface Clock {
  now(): number;
  setTimeout(callback: () => void, ms: number): NodeJS.Timeout;
  clearTimeout(handle: NodeJS.Timeout): void;
}
