import { existsSync } from 'node:fs';
import { mkdir, rm } from 'node:fs/promises';
import path from 'node:path';
import { exec } from 'node:child_process';
import type { Issue, Logger, ServiceConfig, WorkspaceRef } from './types.js';

export class WorkspaceManager {
  constructor(
    private readonly config: ServiceConfig,
    private readonly logger: Logger,
  ) {}

  async ensureWorkspace(issue: Issue): Promise<WorkspaceRef> {
    const workspace_key = sanitizeWorkspaceKey(issue.identifier);
    const workspacePath = path.resolve(this.config.workspace.root, workspace_key);
    assertPathInside(this.config.workspace.root, workspacePath);

    await mkdir(this.config.workspace.root, { recursive: true });
    const created_now = !existsSync(workspacePath);
    await mkdir(workspacePath, { recursive: true });

    const workspace = {
      path: workspacePath,
      workspace_key,
      created_now,
    };

    if (created_now && this.config.hooks.after_create) {
      await this.runHook('after_create', this.config.hooks.after_create, workspacePath, true);
    }

    return workspace;
  }

  async beforeRun(workspace: WorkspaceRef): Promise<void> {
    if (this.config.hooks.before_run) {
      await this.runHook('before_run', this.config.hooks.before_run, workspace.path, true);
    }
  }

  async afterRun(workspace: WorkspaceRef): Promise<void> {
    if (!this.config.hooks.after_run) {
      return;
    }
    try {
      await this.runHook('after_run', this.config.hooks.after_run, workspace.path, false);
    } catch (error) {
      await this.logger.warn('hook.after_run_ignored_failure', { workspace: workspace.path, error: toMessage(error) });
    }
  }

  async removeWorkspace(issueOrIdentifier: Issue | string): Promise<void> {
    const identifier = typeof issueOrIdentifier === 'string' ? issueOrIdentifier : issueOrIdentifier.identifier;
    const workspacePath = path.resolve(this.config.workspace.root, sanitizeWorkspaceKey(identifier));
    assertPathInside(this.config.workspace.root, workspacePath);

    if (!existsSync(workspacePath)) {
      return;
    }

    if (this.config.hooks.before_remove) {
      try {
        await this.runHook('before_remove', this.config.hooks.before_remove, workspacePath, false);
      } catch (error) {
        await this.logger.warn('hook.before_remove_ignored_failure', { workspace: workspacePath, error: toMessage(error) });
      }
    }

    await rm(workspacePath, { recursive: true, force: true });
    await this.logger.info('workspace.removed', { workspace: workspacePath, identifier });
  }

  private async runHook(name: string, script: string, cwd: string, throwOnFailure: boolean): Promise<void> {
    await this.logger.info('hook.started', { name, cwd });
    try {
      await execScript(script, cwd, this.config.hooks.timeout_ms);
      await this.logger.info('hook.completed', { name, cwd });
    } catch (error) {
      await this.logger.error('hook.failed', { name, cwd, error: toMessage(error) });
      if (throwOnFailure) {
        throw error;
      }
    }
  }
}

export function sanitizeWorkspaceKey(identifier: string): string {
  const sanitized = identifier.replace(/[^A-Za-z0-9._-]/g, '_');
  return sanitized.length > 0 ? sanitized : 'issue';
}

export function assertPathInside(root: string, target: string): void {
  const resolvedRoot = path.resolve(root);
  const resolvedTarget = path.resolve(target);
  const relative = path.relative(resolvedRoot, resolvedTarget);
  if (relative.startsWith('..') || path.isAbsolute(relative)) {
    throw new Error(`Workspace path escapes workspace root: ${resolvedTarget}`);
  }
}

export function execScript(script: string, cwd: string, timeoutMs: number): Promise<void> {
  return new Promise((resolve, reject) => {
    exec(script, { cwd, timeout: timeoutMs, windowsHide: true }, (error, stdout, stderr) => {
      if (error) {
        reject(new Error(`${error.message}${stderr ? `\n${stderr}` : ''}${stdout ? `\n${stdout}` : ''}`));
      } else {
        resolve();
      }
    });
  });
}

function toMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
