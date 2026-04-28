import { mkdtemp, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { describe, expect, it } from 'vitest';
import { MemoryLogger } from '../src/logger.js';
import {
  computeFailureBackoff,
  isCandidateEligible,
  Orchestrator,
  sortIssues,
} from '../src/orchestrator.js';
import type { AgentRunner, Clock, Issue, IssueTracker } from '../src/types.js';

function issue(overrides: Partial<Issue>): Issue {
  return {
    id: '1',
    identifier: 'OTR-1',
    title: 'Task',
    description: null,
    priority: null,
    state: 'Todo',
    branch_name: null,
    url: null,
    labels: [],
    blocked_by: [],
    created_at: '2026-04-01T00:00:00Z',
    updated_at: '2026-04-01T00:00:00Z',
    ...overrides,
  };
}

const configLike = {
  tracker: {
    active_states: ['Todo', 'In Progress'],
    terminal_states: ['Done', 'Closed'],
  },
  agent: {
    max_concurrent_agents: 10,
    max_concurrent_agents_by_state: new Map([['todo', 1]]),
  },
} as any;

describe('orchestrator scheduling helpers', () => {
  it('sorts by priority, created time, then identifier', () => {
    expect(
      sortIssues([
        issue({ id: '3', identifier: 'OTR-3', priority: null, created_at: '2026-04-01T00:00:00Z' }),
        issue({ id: '2', identifier: 'OTR-2', priority: 1, created_at: '2026-04-02T00:00:00Z' }),
        issue({ id: '1', identifier: 'OTR-1', priority: 1, created_at: '2026-04-01T00:00:00Z' }),
      ]).map((entry) => entry.identifier),
    ).toEqual(['OTR-1', 'OTR-2', 'OTR-3']);
  });

  it('blocks Todo issues with non-terminal blockers', () => {
    expect(
      isCandidateEligible(
        issue({ blocked_by: [{ id: 'b', identifier: 'OTR-0', state: 'In Progress', created_at: null, updated_at: null }] }),
        configLike,
        new Map(),
        new Set(),
      ),
    ).toBe(false);
    expect(
      isCandidateEligible(
        issue({ blocked_by: [{ id: 'b', identifier: 'OTR-0', state: 'Done', created_at: null, updated_at: null }] }),
        configLike,
        new Map(),
        new Set(),
      ),
    ).toBe(true);
  });

  it('enforces per-state concurrency limits', () => {
    const running = new Map<string, unknown>([
      ['existing', { issue: issue({ id: 'existing', identifier: 'OTR-0', state: 'Todo' }) }],
    ]);

    expect(isCandidateEligible(issue({ id: 'next', identifier: 'OTR-2', state: 'Todo' }), configLike, running, new Set())).toBe(
      false,
    );
    expect(
      isCandidateEligible(issue({ id: 'next', identifier: 'OTR-2', state: 'In Progress' }), configLike, running, new Set()),
    ).toBe(true);
  });

  it('caps exponential backoff', () => {
    expect(computeFailureBackoff(1, 300_000)).toBe(10_000);
    expect(computeFailureBackoff(10, 300_000)).toBe(300_000);
  });
});

describe('Orchestrator', () => {
  it('dispatches eligible candidates in once mode', async () => {
    const root = await mkdtemp(path.join(os.tmpdir(), 'symphony-orchestrator-'));
    const workflowPath = path.join(root, 'WORKFLOW.md');
    await writeFile(
      workflowPath,
      [
        '---',
        'tracker:',
        '  api_key: key',
        '  project_slug: project',
        'workspace:',
        `  root: ${JSON.stringify(path.join(root, 'workspaces'))}`,
        'agent:',
        '  max_concurrent_agents: 1',
        '---',
        'Prompt {{ issue.identifier }}',
      ].join('\n'),
      'utf8',
    );

    const candidates = [issue({ id: '1', identifier: 'OTR-1' })];
    const tracker: IssueTracker = {
      fetchCandidateIssues: async () => candidates,
      fetchIssuesByIds: async () => [],
      fetchTerminalIssues: async () => [],
    };
    const seenPrompts: string[] = [];
    const runner: AgentRunner = {
      run: async (input) => {
        seenPrompts.push(input.prompt);
        return { status: 'succeeded' };
      },
    };
    const clock: Clock = {
      now: () => 1_000,
      setTimeout: (() => ({}) as NodeJS.Timeout) as Clock['setTimeout'],
      clearTimeout: () => undefined,
    };

    const orchestrator = new Orchestrator({
      workflowPath,
      once: true,
      logger: new MemoryLogger(),
      trackerFactory: () => tracker,
      runner,
      clock,
    });

    await orchestrator.start();

    expect(seenPrompts).toEqual(['Prompt OTR-1']);
    expect(orchestrator.completed.has('1')).toBe(true);
  });
});
