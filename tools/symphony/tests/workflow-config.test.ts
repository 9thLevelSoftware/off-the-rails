import path from 'node:path';
import { describe, expect, it } from 'vitest';
import { resolveConfig, validateConfig } from '../src/config.js';
import { parseWorkflowContent, renderPrompt, WorkflowError } from '../src/workflow.js';
import type { Issue } from '../src/types.js';

const issue: Issue = {
  id: 'issue-id',
  identifier: 'OTR-1',
  title: 'Add a thing',
  description: 'Ticket body',
  priority: 2,
  state: 'Todo',
  branch_name: null,
  url: 'https://linear.app/test/issue/OTR-1',
  labels: ['feature'],
  blocked_by: [],
  created_at: '2026-04-01T00:00:00Z',
  updated_at: '2026-04-01T00:00:00Z',
};

describe('workflow parsing and prompt rendering', () => {
  it('parses optional YAML front matter and trims the prompt body', () => {
    const workflow = parseWorkflowContent(
      [
        '---',
        'tracker:',
        '  kind: linear',
        'polling:',
        '  interval_ms: 1234',
        '---',
        '',
        'Hello {{ issue.identifier }}',
        '',
      ].join('\n'),
      'C:/repo/WORKFLOW.md',
    );

    expect(workflow.config.tracker).toEqual({ kind: 'linear' });
    expect(workflow.prompt_template).toBe('Hello {{ issue.identifier }}');
  });

  it('rejects non-object YAML front matter', () => {
    expect(() => parseWorkflowContent(['---', '- nope', '---', 'body'].join('\n'))).toThrow(WorkflowError);
  });

  it('uses strict rendering for unknown variables', async () => {
    await expect(renderPrompt('Hello {{ missing.value }}', { issue, attempt: null })).rejects.toMatchObject({
      code: 'template_render_error',
    });
  });

  it('renders issue context and retry attempt', async () => {
    await expect(renderPrompt('{{ issue.identifier }} attempt={{ attempt }}', { issue, attempt: 3 })).resolves.toBe(
      'OTR-1 attempt=3',
    );
  });
});

describe('config resolution and validation', () => {
  it('resolves env-backed Linear settings and workspace paths', () => {
    const workflow = parseWorkflowContent(
      [
        '---',
        'tracker:',
        '  kind: linear',
        '  api_key: "$LINEAR_API_KEY"',
        '  project_slug: "$LINEAR_PROJECT_SLUG"',
        'workspace:',
        '  root: workspaces',
        'codex:',
        '  turn_sandbox_policy:',
        '    type: workspaceWrite',
        '    writableRoots:',
        '      - workspaces',
        'agent:',
        '  max_concurrent_agents_by_state:',
        '    todo: 2',
        '---',
        'Prompt',
      ].join('\n'),
      path.join(process.cwd(), 'WORKFLOW.md'),
    );

    const config = resolveConfig(workflow, {
      LINEAR_API_KEY: 'lin-key',
      LINEAR_PROJECT_SLUG: 'otr',
    });

    expect(config.tracker.api_key).toBe('lin-key');
    expect(config.tracker.project_slug).toBe('otr');
    expect(config.workspace.root).toBe(path.resolve(process.cwd(), 'workspaces'));
    expect(config.codex.turn_sandbox_policy).toMatchObject({
      type: 'workspaceWrite',
      writableRoots: [path.resolve(process.cwd(), 'workspaces')],
      readOnlyAccess: { type: 'fullAccess' },
    });
    expect(config.agent.max_concurrent_agents_by_state.get('todo')).toBe(2);
  });

  it('reports missing secrets only when required', () => {
    const config = resolveConfig(parseWorkflowContent('Prompt', path.join(process.cwd(), 'WORKFLOW.md')), {});

    expect(validateConfig(config, { requireSecrets: false })).not.toContain(
      'tracker.api_key is required; set LINEAR_API_KEY or tracker.api_key',
    );
    expect(validateConfig(config, { requireSecrets: true })).toEqual(
      expect.arrayContaining([
        'tracker.api_key is required; set LINEAR_API_KEY or tracker.api_key',
        'tracker.project_slug is required; set LINEAR_PROJECT_SLUG or tracker.project_slug',
      ]),
    );
  });
});
