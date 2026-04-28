import { resolveConfig, validateConfig } from './config.js';
import { LinearClient } from './linear.js';
import { renderPrompt, type WorkflowError, loadWorkflow } from './workflow.js';
import { WorkspaceManager } from './workspace.js';
import type {
  AgentRunner,
  Clock,
  Issue,
  IssueTracker,
  Logger,
  RetryEntry,
  ServiceConfig,
  WorkspaceRef,
} from './types.js';

export interface OrchestratorOptions {
  workflowPath: string;
  logsRoot?: string;
  dryRun?: boolean;
  once?: boolean;
  logger: Logger;
  trackerFactory?: (config: ServiceConfig) => IssueTracker;
  workspaceFactory?: (config: ServiceConfig, logger: Logger) => WorkspaceManager;
  runner: AgentRunner;
  clock?: Clock;
}

interface RunningEntry {
  issue: Issue;
  workspace: WorkspaceRef;
  started_at: number;
  promise: Promise<void>;
}

export class Orchestrator {
  readonly running = new Map<string, RunningEntry>();
  readonly claimed = new Set<string>();
  readonly retry_attempts = new Map<string, RetryEntry>();
  readonly completed = new Set<string>();

  private config: ServiceConfig | null = null;

  constructor(private readonly options: OrchestratorOptions) {}

  async start(): Promise<void> {
    await this.startupCleanup();
    await this.tick();

    if (this.options.once) {
      await Promise.all([...this.running.values()].map((entry) => entry.promise));
      return;
    }

    const loop = async (): Promise<void> => {
      await this.tick();
      this.options.clock?.setTimeout(loop, this.effectiveConfig().polling.interval_ms) ??
        setTimeout(loop, this.effectiveConfig().polling.interval_ms);
    };

    this.options.clock?.setTimeout(loop, this.effectiveConfig().polling.interval_ms) ??
      setTimeout(loop, this.effectiveConfig().polling.interval_ms);
  }

  async tick(): Promise<void> {
    const configResult = await this.reloadConfig(!this.options.dryRun);
    if (!configResult.ok) {
      await this.options.logger.error('orchestrator.config_invalid', { errors: configResult.errors });
      return;
    }

    const config = configResult.config;
    await this.reconcileRunning(config);

    if (this.options.dryRun && (!config.tracker.api_key || !config.tracker.project_slug)) {
      await this.options.logger.warn('orchestrator.dry_run_skipped_linear', {
        reason: 'LINEAR_API_KEY and LINEAR_PROJECT_SLUG are required to fetch candidates',
      });
      return;
    }

    const tracker = this.tracker(config);
    const candidates = sortIssues(await tracker.fetchCandidateIssues(config.tracker.active_states));
    const availableSlots = this.availableSlots(config);
    await this.options.logger.info('orchestrator.candidates_loaded', {
      count: candidates.length,
      available_slots: availableSlots,
      dry_run: Boolean(this.options.dryRun),
    });

    if (this.options.dryRun) {
      for (const issue of candidates) {
        await this.options.logger.info('orchestrator.dry_run_candidate', {
          issue: issue.identifier,
          state: issue.state,
          eligible: isCandidateEligible(issue, config, this.running, this.claimed),
        });
      }
      return;
    }

    for (const issue of candidates) {
      if (this.availableSlots(config) <= 0) {
        break;
      }
      if (!isCandidateEligible(issue, config, this.running, this.claimed)) {
        continue;
      }
      await this.dispatch(issue, config, null);
    }
  }

  async dispatch(issue: Issue, config: ServiceConfig, attempt: number | null): Promise<void> {
    if (this.running.has(issue.id) || this.claimed.has(issue.id)) {
      return;
    }

    this.claimed.add(issue.id);
    const workspaceManager = this.workspace(config);
    const workspace = await workspaceManager.ensureWorkspace(issue);
    const prompt = await renderPrompt((await loadWorkflow(config.workflow_path)).prompt_template, { issue, attempt });
    await workspaceManager.beforeRun(workspace);

    const promise = this.options.runner
      .run({ issue, attempt, prompt, workspace, config })
      .then(async (result) => {
        await workspaceManager.afterRun(workspace);
        this.running.delete(issue.id);
        this.claimed.delete(issue.id);

        if (result.status === 'succeeded') {
          this.completed.add(issue.id);
          await this.options.logger.info('orchestrator.run_succeeded', { issue: issue.identifier });
          this.scheduleRetry(issue, 1, config, 'continuation');
        } else {
          const nextAttempt = (attempt ?? 0) + 1;
          await this.options.logger.warn('orchestrator.run_failed', {
            issue: issue.identifier,
            status: result.status,
            error: result.error,
            next_attempt: nextAttempt,
          });
          this.scheduleRetry(issue, nextAttempt, config, result.error ?? result.status);
        }
      })
      .catch(async (error) => {
        this.running.delete(issue.id);
        this.claimed.delete(issue.id);
        const nextAttempt = (attempt ?? 0) + 1;
        await this.options.logger.error('orchestrator.run_crashed', {
          issue: issue.identifier,
          error: error instanceof Error ? error.message : String(error),
          next_attempt: nextAttempt,
        });
        this.scheduleRetry(issue, nextAttempt, config, error instanceof Error ? error.message : String(error));
      });

    this.running.set(issue.id, {
      issue,
      workspace,
      started_at: this.now(),
      promise,
    });
    await this.options.logger.info('orchestrator.dispatched', { issue: issue.identifier, workspace: workspace.path });
  }

  private async reloadConfig(requireSecrets: boolean): Promise<
    | { ok: true; config: ServiceConfig }
    | { ok: false; errors: string[]; error?: WorkflowError | Error }
  > {
    try {
      const workflow = await loadWorkflow(this.options.workflowPath);
      const config = resolveConfig(workflow);
      const errors = validateConfig(config, { requireSecrets });
      if (errors.length > 0) {
        return { ok: false, errors };
      }
      this.config = config;
      return { ok: true, config };
    } catch (error) {
      return { ok: false, errors: [error instanceof Error ? error.message : String(error)], error: error as Error };
    }
  }

  private async startupCleanup(): Promise<void> {
    const configResult = await this.reloadConfig(!this.options.dryRun);
    if (!configResult.ok) {
      await this.options.logger.warn('orchestrator.startup_cleanup_skipped', { errors: configResult.errors });
      return;
    }
    const config = configResult.config;
    if (this.options.dryRun && (!config.tracker.api_key || !config.tracker.project_slug)) {
      return;
    }
    try {
      const terminalIssues = await this.tracker(config).fetchTerminalIssues(config.tracker.terminal_states);
      const workspaceManager = this.workspace(config);
      for (const issue of terminalIssues) {
        await workspaceManager.removeWorkspace(issue);
      }
    } catch (error) {
      await this.options.logger.warn('orchestrator.startup_cleanup_failed', {
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }

  private async reconcileRunning(config: ServiceConfig): Promise<void> {
    const runningIds = [...this.running.keys()];
    if (runningIds.length === 0) {
      return;
    }

    if (config.codex.stall_timeout_ms > 0) {
      for (const [issueId, entry] of this.running.entries()) {
        if (this.now() - entry.started_at > config.codex.stall_timeout_ms) {
          await this.cancelRun(issueId, 'stalled');
          this.scheduleRetry(entry.issue, 1, config, 'stalled');
        }
      }
    }

    try {
      const refreshed = await this.tracker(config).fetchIssuesByIds(runningIds);
      const byId = new Map(refreshed.map((issue) => [issue.id, issue]));
      for (const [issueId, entry] of this.running.entries()) {
        const fresh = byId.get(issueId);
        if (!fresh) {
          continue;
        }
        entry.issue = fresh;
        if (isTerminalState(fresh.state, config)) {
          await this.cancelRun(issueId, 'terminal_state');
          await this.workspace(config).removeWorkspace(fresh);
        } else if (!isActiveState(fresh.state, config)) {
          await this.cancelRun(issueId, 'inactive_state');
        }
      }
    } catch (error) {
      await this.options.logger.warn('orchestrator.reconcile_state_failed', {
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }

  private async cancelRun(issueId: string, reason: string): Promise<void> {
    const entry = this.running.get(issueId);
    if (!entry) {
      return;
    }
    await this.options.runner.cancel?.(issueId, reason);
    this.running.delete(issueId);
    this.claimed.delete(issueId);
    await this.options.logger.warn('orchestrator.run_canceled', { issue: entry.issue.identifier, reason });
  }

  private scheduleRetry(issue: Issue, attempt: number, config: ServiceConfig, error: string): void {
    const delay = error === 'continuation' ? 1_000 : computeFailureBackoff(attempt, config.agent.max_retry_backoff_ms);
    const dueAt = this.now() + delay;
    this.retry_attempts.set(issue.id, {
      issue_id: issue.id,
      identifier: issue.identifier,
      attempt,
      due_at_ms: dueAt,
      error,
    });

    const fire = async (): Promise<void> => {
      const entry = this.retry_attempts.get(issue.id);
      if (!entry) {
        return;
      }
      this.retry_attempts.delete(issue.id);
      this.claimed.delete(issue.id);
      const latestConfig = this.effectiveConfig();
      const candidates = await this.tracker(latestConfig).fetchCandidateIssues(latestConfig.tracker.active_states);
      const candidate = candidates.find((current) => current.id === issue.id);
      if (!candidate || !isCandidateEligible(candidate, latestConfig, this.running, this.claimed)) {
        return;
      }
      await this.dispatch(candidate, latestConfig, attempt);
    };

    this.claimed.add(issue.id);
    this.options.clock?.setTimeout(() => void fire(), delay) ?? setTimeout(() => void fire(), delay);
  }

  private availableSlots(config: ServiceConfig): number {
    return Math.max(config.agent.max_concurrent_agents - this.running.size, 0);
  }

  private effectiveConfig(): ServiceConfig {
    if (!this.config) {
      throw new Error('Config has not been loaded');
    }
    return this.config;
  }

  private tracker(config: ServiceConfig): IssueTracker {
    return this.options.trackerFactory?.(config) ?? new LinearClient(config);
  }

  private workspace(config: ServiceConfig): WorkspaceManager {
    return this.options.workspaceFactory?.(config, this.options.logger) ?? new WorkspaceManager(config, this.options.logger);
  }

  private now(): number {
    return this.options.clock?.now() ?? Date.now();
  }
}

export function sortIssues(issues: Issue[]): Issue[] {
  return [...issues].sort((left, right) => {
    const leftPriority = left.priority ?? Number.POSITIVE_INFINITY;
    const rightPriority = right.priority ?? Number.POSITIVE_INFINITY;
    if (leftPriority !== rightPriority) {
      return leftPriority - rightPriority;
    }

    const leftCreated = left.created_at ? Date.parse(left.created_at) : Number.POSITIVE_INFINITY;
    const rightCreated = right.created_at ? Date.parse(right.created_at) : Number.POSITIVE_INFINITY;
    if (leftCreated !== rightCreated) {
      return leftCreated - rightCreated;
    }

    return left.identifier.localeCompare(right.identifier);
  });
}

export function isCandidateEligible(
  issue: Issue,
  config: ServiceConfig,
  running: Map<string, unknown>,
  claimed: Set<string>,
): boolean {
  if (!issue.id || !issue.identifier || !issue.title || !issue.state) {
    return false;
  }
  if (!isActiveState(issue.state, config) || isTerminalState(issue.state, config)) {
    return false;
  }
  if (running.has(issue.id) || claimed.has(issue.id)) {
    return false;
  }
  if (!hasStateSlot(issue, config, running)) {
    return false;
  }
  if (issue.state.toLowerCase() === 'todo') {
    return issue.blocked_by.every((blocker) => !blocker.state || isTerminalState(blocker.state, config));
  }
  return true;
}

export function hasStateSlot(issue: Issue, config: ServiceConfig, running: Map<string, unknown>): boolean {
  const normalizedState = issue.state.toLowerCase();
  const limit = config.agent.max_concurrent_agents_by_state.get(normalizedState) ?? config.agent.max_concurrent_agents;
  let runningInState = 0;

  for (const entry of running.values()) {
    const state = readRunningState(entry);
    if (state?.toLowerCase() === normalizedState) {
      runningInState += 1;
    }
  }

  return runningInState < limit;
}

export function isActiveState(state: string, config: ServiceConfig): boolean {
  return config.tracker.active_states.map((entry) => entry.toLowerCase()).includes(state.toLowerCase());
}

export function isTerminalState(state: string, config: ServiceConfig): boolean {
  return config.tracker.terminal_states.map((entry) => entry.toLowerCase()).includes(state.toLowerCase());
}

export function computeFailureBackoff(attempt: number, maxRetryBackoffMs: number): number {
  return Math.min(10_000 * 2 ** Math.max(attempt - 1, 0), maxRetryBackoffMs);
}

function readRunningState(entry: unknown): string | null {
  if (typeof entry !== 'object' || entry === null || !('issue' in entry)) {
    return null;
  }
  const issue = (entry as { issue?: unknown }).issue;
  if (typeof issue !== 'object' || issue === null || !('state' in issue)) {
    return null;
  }
  const state = (issue as { state?: unknown }).state;
  return typeof state === 'string' ? state : null;
}
