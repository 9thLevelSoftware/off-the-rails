import { mkdtemp, readFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import { resolveConfig } from '../src/config.js';
import { MemoryLogger } from '../src/logger.js';
import { assertPathInside, sanitizeWorkspaceKey, WorkspaceManager } from '../src/workspace.js';
import { parseWorkflowContent } from '../src/workflow.js';
import type { Issue } from '../src/types.js';

const issue: Issue = {
  id: '1',
  identifier: 'OTR/1 bad',
  title: 'Task',
  description: null,
  priority: null,
  state: 'Todo',
  branch_name: null,
  url: null,
  labels: [],
  blocked_by: [],
  created_at: null,
  updated_at: null,
};

describe('workspace management', () => {
  it('sanitizes Linear identifiers for filesystem paths', () => {
    expect(sanitizeWorkspaceKey('OTR/1 bad')).toBe('OTR_1_bad');
  });

  it('rejects paths outside the workspace root', () => {
    expect(() => assertPathInside('/tmp/root', '/tmp/root/child')).not.toThrow();
    expect(() => assertPathInside('/tmp/root', '/tmp/other')).toThrow('escapes workspace root');
  });

  it('creates workspaces and runs after_create hooks only once', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'symphony-workspace-'));
    const workflow = parseWorkflowContent(
      [
        '---',
        'workspace:',
        `  root: ${JSON.stringify(root)}`,
        'hooks:',
        '  after_create: node -e "require(\'fs\').writeFileSync(\'marker.txt\', \'ok\')"',
        '---',
        'Prompt',
      ].join('\n'),
      path.join(root, 'WORKFLOW.md'),
    );
    const config = resolveConfig(workflow, {});
    const manager = new WorkspaceManager(config, new MemoryLogger());

    const first = await manager.ensureWorkspace(issue);
    const second = await manager.ensureWorkspace(issue);

    expect(first.created_now).toBe(true);
    expect(second.created_now).toBe(false);
    await expect(readFile(path.join(first.path, 'marker.txt'), 'utf8')).resolves.toBe('ok');
  });
});
