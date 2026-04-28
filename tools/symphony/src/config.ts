import os from 'node:os';
import path from 'node:path';
import type {
  AgentConfig,
  CodexConfig,
  PollingConfig,
  ServiceConfig,
  TrackerConfig,
  WorkflowDefinition,
  WorkspaceConfig,
  WorkspaceHooks,
} from './types.js';

export interface ValidationOptions {
  requireSecrets: boolean;
}

export function resolveConfig(
  workflow: WorkflowDefinition,
  env: NodeJS.ProcessEnv = process.env,
): ServiceConfig {
  const workflowPath = path.resolve(workflow.path);
  const workflowDir = path.dirname(workflowPath);
  const root = objectAt(workflow.config, 'workspace');
  const tracker = resolveTrackerConfig(objectAt(workflow.config, 'tracker'), env);
  const polling = resolvePollingConfig(objectAt(workflow.config, 'polling'));
  const hooks = resolveHooksConfig(objectAt(workflow.config, 'hooks'));
  const workspace = resolveWorkspaceConfig(root, workflowDir, env);
  const agent = resolveAgentConfig(objectAt(workflow.config, 'agent'));
  const codex = resolveCodexConfig(objectAt(workflow.config, 'codex'), workspace.root, workflowDir, env);

  return {
    workflow_path: workflowPath,
    workflow_dir: workflowDir,
    tracker,
    polling,
    workspace,
    hooks,
    agent,
    codex,
  };
}

export function validateConfig(config: ServiceConfig, options: ValidationOptions): string[] {
  const errors: string[] = [];

  if (config.tracker.kind !== 'linear') {
    errors.push(`Unsupported tracker.kind: ${config.tracker.kind}`);
  }
  if (!config.tracker.endpoint) {
    errors.push('tracker.endpoint is required');
  }
  if (options.requireSecrets && !config.tracker.api_key) {
    errors.push('tracker.api_key is required; set LINEAR_API_KEY or tracker.api_key');
  }
  if (options.requireSecrets && !config.tracker.project_slug) {
    errors.push('tracker.project_slug is required; set LINEAR_PROJECT_SLUG or tracker.project_slug');
  }
  if (!config.codex.command.trim()) {
    errors.push('codex.command is required');
  }
  if (config.polling.interval_ms <= 0) {
    errors.push('polling.interval_ms must be positive');
  }
  if (config.hooks.timeout_ms <= 0) {
    errors.push('hooks.timeout_ms must be positive');
  }
  if (config.agent.max_concurrent_agents <= 0) {
    errors.push('agent.max_concurrent_agents must be positive');
  }
  if (config.agent.max_turns <= 0) {
    errors.push('agent.max_turns must be positive');
  }
  if (config.agent.max_retry_backoff_ms <= 0) {
    errors.push('agent.max_retry_backoff_ms must be positive');
  }
  if (config.codex.turn_timeout_ms <= 0) {
    errors.push('codex.turn_timeout_ms must be positive');
  }
  if (config.codex.read_timeout_ms <= 0) {
    errors.push('codex.read_timeout_ms must be positive');
  }

  return errors;
}

function resolveTrackerConfig(raw: Record<string, unknown>, env: NodeJS.ProcessEnv): TrackerConfig {
  const kind = stringAt(raw, 'kind', 'linear');
  const endpoint = stringAt(raw, 'endpoint', 'https://api.linear.app/graphql');
  const configuredApiKey = stringOrNull(raw.api_key);
  const configuredProjectSlug = stringOrNull(raw.project_slug);

  return {
    kind: kind === 'linear' ? 'linear' : (kind as 'linear'),
    endpoint,
    api_key: resolveEnvBackedValue(configuredApiKey, env) ?? env.LINEAR_API_KEY ?? null,
    project_slug: resolveEnvBackedValue(configuredProjectSlug, env) ?? env.LINEAR_PROJECT_SLUG ?? null,
    active_states: stringListAt(raw, 'active_states', ['Todo', 'In Progress']),
    terminal_states: stringListAt(raw, 'terminal_states', ['Closed', 'Cancelled', 'Canceled', 'Duplicate', 'Done']),
  };
}

function resolvePollingConfig(raw: Record<string, unknown>): PollingConfig {
  return {
    interval_ms: positiveIntegerAt(raw, 'interval_ms', 30_000),
  };
}

function resolveHooksConfig(raw: Record<string, unknown>): WorkspaceHooks {
  return {
    after_create: stringOrNull(raw.after_create),
    before_run: stringOrNull(raw.before_run),
    after_run: stringOrNull(raw.after_run),
    before_remove: stringOrNull(raw.before_remove),
    timeout_ms: positiveIntegerAt(raw, 'timeout_ms', 60_000),
  };
}

function resolveWorkspaceConfig(raw: Record<string, unknown>, workflowDir: string, env: NodeJS.ProcessEnv): WorkspaceConfig {
  const configuredRoot = stringOrNull(raw.root) ?? '~/code/off-the-rails-symphony-workspaces';
  return {
    root: resolvePathValue(configuredRoot, workflowDir, env),
  };
}

function resolveAgentConfig(raw: Record<string, unknown>): AgentConfig {
  return {
    max_concurrent_agents: positiveIntegerAt(raw, 'max_concurrent_agents', 10),
    max_turns: positiveIntegerAt(raw, 'max_turns', 20),
    max_retry_backoff_ms: positiveIntegerAt(raw, 'max_retry_backoff_ms', 300_000),
    max_concurrent_agents_by_state: positiveIntegerMap(raw.max_concurrent_agents_by_state),
  };
}

function resolveCodexConfig(
  raw: Record<string, unknown>,
  workspaceRoot: string,
  workflowDir: string,
  env: NodeJS.ProcessEnv,
): CodexConfig {
  const turnSandboxPolicy = normalizeWorkspaceWritePolicy(raw.turn_sandbox_policy, workspaceRoot, workflowDir, env) ?? {
    type: 'workspaceWrite',
    writableRoots: [workspaceRoot],
    readOnlyAccess: { type: 'fullAccess' },
    networkAccess: true,
    excludeTmpdirEnvVar: false,
    excludeSlashTmp: false,
  };

  return {
    command: stringAt(raw, 'command', 'codex --config shell_environment_policy.inherit=all app-server'),
    approval_policy: raw.approval_policy ?? 'never',
    thread_sandbox: raw.thread_sandbox ?? 'workspace-write',
    turn_sandbox_policy: turnSandboxPolicy,
    turn_timeout_ms: positiveIntegerAt(raw, 'turn_timeout_ms', 3_600_000),
    read_timeout_ms: positiveIntegerAt(raw, 'read_timeout_ms', 5_000),
    stall_timeout_ms: integerAt(raw, 'stall_timeout_ms', 300_000),
    model: stringOrNull(raw.model),
    model_reasoning_effort: stringOrNull(raw.model_reasoning_effort),
  };
}

function resolvePathValue(value: string, workflowDir: string, env: NodeJS.ProcessEnv): string {
  let expanded = resolveEnvBackedValue(value, env) ?? value;
  if (expanded === '~' || expanded.startsWith('~/') || expanded.startsWith('~\\')) {
    expanded = path.join(os.homedir(), expanded.slice(2));
  }
  return path.resolve(path.isAbsolute(expanded) ? expanded : path.join(workflowDir, expanded));
}

function normalizeWorkspaceWritePolicy(
  value: unknown,
  workspaceRoot: string,
  workflowDir: string,
  env: NodeJS.ProcessEnv,
): unknown | null {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    return value ?? null;
  }

  const policy = value as Record<string, unknown>;
  if (policy.type !== 'workspaceWrite') {
    return policy;
  }

  const writableRoots = Array.isArray(policy.writableRoots)
    ? policy.writableRoots
        .filter((entry): entry is string => typeof entry === 'string' && entry.trim().length > 0)
        .map((entry) => resolvePathValue(entry, workflowDir, env))
    : [workspaceRoot];

  return {
    ...policy,
    writableRoots,
    readOnlyAccess:
      typeof policy.readOnlyAccess === 'object' && policy.readOnlyAccess !== null
        ? policy.readOnlyAccess
        : { type: 'fullAccess' },
    networkAccess: typeof policy.networkAccess === 'boolean' ? policy.networkAccess : true,
    excludeTmpdirEnvVar:
      typeof policy.excludeTmpdirEnvVar === 'boolean' ? policy.excludeTmpdirEnvVar : false,
    excludeSlashTmp: typeof policy.excludeSlashTmp === 'boolean' ? policy.excludeSlashTmp : false,
  };
}

function resolveEnvBackedValue(value: string | null, env: NodeJS.ProcessEnv): string | null {
  if (!value) {
    return null;
  }
  if (/^\$[A-Za-z_][A-Za-z0-9_]*$/.test(value)) {
    const resolved = env[value.slice(1)];
    return resolved && resolved.trim().length > 0 ? resolved : null;
  }
  return value;
}

function objectAt(root: Record<string, unknown>, key: string): Record<string, unknown> {
  const value = root[key];
  return typeof value === 'object' && value !== null && !Array.isArray(value) ? (value as Record<string, unknown>) : {};
}

function stringAt(root: Record<string, unknown>, key: string, fallback: string): string {
  return typeof root[key] === 'string' && (root[key] as string).trim().length > 0 ? (root[key] as string) : fallback;
}

function stringOrNull(value: unknown): string | null {
  return typeof value === 'string' && value.trim().length > 0 ? value : null;
}

function stringListAt(root: Record<string, unknown>, key: string, fallback: string[]): string[] {
  const value = root[key];
  if (!Array.isArray(value)) {
    return fallback;
  }

  const strings = value.filter((entry): entry is string => typeof entry === 'string' && entry.trim().length > 0);
  return strings.length > 0 ? strings : fallback;
}

function integerAt(root: Record<string, unknown>, key: string, fallback: number): number {
  const value = root[key];
  if (typeof value === 'number' && Number.isInteger(value)) {
    return value;
  }
  return fallback;
}

function positiveIntegerAt(root: Record<string, unknown>, key: string, fallback: number): number {
  const value = integerAt(root, key, fallback);
  return value > 0 ? value : fallback;
}

function positiveIntegerMap(value: unknown): Map<string, number> {
  const result = new Map<string, number>();
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    return result;
  }

  for (const [key, entry] of Object.entries(value)) {
    if (typeof entry === 'number' && Number.isInteger(entry) && entry > 0) {
      result.set(key.toLowerCase(), entry);
    }
  }

  return result;
}
