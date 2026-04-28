import { describe, expect, it } from 'vitest';
import { resolveConfig } from '../src/config.js';
import { ISSUES_BY_PROJECT_AND_STATE_QUERY, LinearClient, normalizeIssueNodes } from '../src/linear.js';
import { parseWorkflowContent } from '../src/workflow.js';

function config() {
  return resolveConfig(
    parseWorkflowContent(
      [
        '---',
        'tracker:',
        '  api_key: "$LINEAR_API_KEY"',
        '  project_slug: "$LINEAR_PROJECT_SLUG"',
        '---',
        'Prompt',
      ].join('\n'),
      'C:/repo/WORKFLOW.md',
    ),
    { LINEAR_API_KEY: 'lin-key', LINEAR_PROJECT_SLUG: 'off-the-rails' },
  );
}

describe('LinearClient', () => {
  it('sends authenticated GraphQL requests and paginates issue results', async () => {
    const calls: Array<{ body: { query: string; variables: Record<string, unknown> }; auth: string | null }> = [];
    const fetchMock = async (_input: string, init: RequestInit): Promise<Response> => {
      calls.push({
        body: JSON.parse(String(init.body)) as { query: string; variables: Record<string, unknown> },
        auth: new Headers(init.headers).get('Authorization'),
      });
      const firstCall = calls.length === 1;
      return new Response(
        JSON.stringify({
          data: {
            issues: {
              nodes: [
                {
                  id: firstCall ? '1' : '2',
                  identifier: firstCall ? 'OTR-1' : 'OTR-2',
                  title: 'Task',
                  state: { name: 'Todo' },
                  labels: { nodes: [{ name: 'Feature' }] },
                  relations: { nodes: [] },
                  createdAt: '2026-04-01T00:00:00Z',
                },
              ],
              pageInfo: { hasNextPage: firstCall, endCursor: firstCall ? 'cursor-1' : null },
            },
          },
        }),
        { status: 200 },
      );
    };

    const client = new LinearClient(config(), fetchMock);
    const issues = await client.fetchCandidateIssues(['Todo']);

    expect(issues.map((issue) => issue.identifier)).toEqual(['OTR-1', 'OTR-2']);
    expect(calls).toHaveLength(2);
    expect(calls[0]?.auth).toBe('lin-key');
    expect(calls[0]?.body.query).toBe(ISSUES_BY_PROJECT_AND_STATE_QUERY);
    expect(calls[0]?.body.variables).toMatchObject({
      projectSlug: 'off-the-rails',
      states: ['Todo'],
      after: null,
    });
    expect(calls[1]?.body.variables.after).toBe('cursor-1');
  });

  it('normalizes labels and blocker relations', () => {
    const [issue] = normalizeIssueNodes([
      {
        id: '1',
        identifier: 'OTR-1',
        title: 'Blocked task',
        priority: 0,
        state: { name: 'Todo' },
        labels: { nodes: [{ name: 'Bug' }] },
        relations: {
          nodes: [
            {
              type: 'blocked_by',
              relatedIssue: {
                id: 'blocker',
                identifier: 'OTR-0',
                state: { name: 'In Progress' },
                createdAt: '2026-03-01T00:00:00Z',
                updatedAt: '2026-03-02T00:00:00Z',
              },
            },
          ],
        },
      },
    ]);

    expect(issue?.priority).toBeNull();
    expect(issue?.labels).toEqual(['bug']);
    expect(issue?.blocked_by).toEqual([
      {
        id: 'blocker',
        identifier: 'OTR-0',
        state: 'In Progress',
        created_at: '2026-03-01T00:00:00Z',
        updated_at: '2026-03-02T00:00:00Z',
      },
    ]);
  });

  it('surfaces GraphQL errors even when HTTP status is ok', async () => {
    const fetchMock = async (): Promise<Response> =>
      new Response(JSON.stringify({ errors: [{ message: 'bad query' }] }), { status: 200 });

    const client = new LinearClient(config(), fetchMock);
    await expect(client.fetchCandidateIssues(['Todo'])).rejects.toThrow('bad query');
  });
});
