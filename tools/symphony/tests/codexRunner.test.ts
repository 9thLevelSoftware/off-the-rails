import { describe, expect, it } from 'vitest';
import { CodexAgentRunner, linearGraphqlToolSpec, type AppServerTransport } from '../src/codexRunner.js';
import { resolveConfig } from '../src/config.js';
import { LinearClient } from '../src/linear.js';
import { MemoryLogger } from '../src/logger.js';
import { parseWorkflowContent } from '../src/workflow.js';
import type { AgentRunInput, Issue } from '../src/types.js';

class FakeTransport implements AppServerTransport {
  pid = 123;
  readonly requests: Array<{ method: string; params: unknown }> = [];
  readonly responses: Array<{ id: string | number; result: unknown }> = [];
  private callback: ((message: Record<string, unknown>) => void) | null = null;

  start(): void {}

  async stop(): Promise<void> {}

  async request(method: string, params: unknown): Promise<Record<string, unknown>> {
    this.requests.push({ method, params });
    if (method === 'thread/start') {
      return { thread: { id: 'thread-1' } };
    }
    if (method === 'turn/start') {
      this.callback?.({ method: 'turn/started', params: { threadId: 'thread-1', turnId: 'turn-1' } });
      this.callback?.({ method: 'turn/completed', params: { threadId: 'thread-1', turn: { id: 'turn-1' } } });
    }
    return {};
  }

  respond(id: string | number, result: unknown): void {
    this.responses.push({ id, result });
  }

  notify(): void {}

  onMessage(callback: (message: Record<string, unknown>) => void): void {
    this.callback = callback;
  }
}

const issue: Issue = {
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
  created_at: null,
  updated_at: null,
};

describe('CodexAgentRunner', () => {
  it('declares the linear_graphql dynamic tool', () => {
    expect(linearGraphqlToolSpec()).toMatchObject({
      namespace: 'linear',
      name: 'linear_graphql',
      inputSchema: {
        required: ['query'],
      },
    });
  });

  it('starts a thread and turn through the app-server transport', async () => {
    const fakeTransport = new FakeTransport();
    const config = resolveConfig(
      parseWorkflowContent(
        [
          '---',
          'tracker:',
          '  api_key: key',
          '  project_slug: project',
          'workspace:',
          '  root: .',
          'codex:',
          '  command: codex app-server',
          '---',
          'Prompt',
        ].join('\n'),
        process.cwd() + '/WORKFLOW.md',
      ),
      {},
    );
    const input: AgentRunInput = {
      issue,
      attempt: null,
      prompt: 'Do work',
      workspace: { path: process.cwd(), workspace_key: 'OTR-1', created_now: false },
      config,
    };

    const runner = new CodexAgentRunner(
      new MemoryLogger(),
      (serviceConfig) => new LinearClient(serviceConfig, async () => new Response(JSON.stringify({ data: {} }))),
      () => fakeTransport,
    );

    await expect(runner.run(input)).resolves.toMatchObject({ status: 'succeeded' });
    expect(fakeTransport.requests.map((request) => request.method)).toEqual(['initialize', 'thread/start', 'turn/start']);
    expect(fakeTransport.requests[1]?.params).toMatchObject({
      dynamicTools: [expect.objectContaining({ name: 'linear_graphql' })],
    });
  });

  it('responds to linear_graphql dynamic tool calls', async () => {
    const fakeTransport = new FakeTransport();
    fakeTransport.request = async (method: string, params: unknown): Promise<Record<string, unknown>> => {
      fakeTransport.requests.push({ method, params });
      if (method === 'thread/start') {
        return { thread: { id: 'thread-1' } };
      }
      if (method === 'turn/start') {
        fakeTransport['callback']?.({
          id: 'server-request-1',
          method: 'item/tool/call',
          params: {
            threadId: 'thread-1',
            turnId: 'turn-1',
            callId: 'call-1',
            namespace: 'linear',
            tool: 'linear_graphql',
            arguments: { query: 'query { viewer { id } }' },
          },
        });
        fakeTransport['callback']?.({ method: 'turn/completed', params: { threadId: 'thread-1', turn: { id: 'turn-1' } } });
      }
      return {};
    };

    const config = resolveConfig(
      parseWorkflowContent(
        ['---', 'tracker:', '  api_key: key', '  project_slug: project', 'workspace:', '  root: .', '---', 'Prompt'].join(
          '\n',
        ),
        process.cwd() + '/WORKFLOW.md',
      ),
      {},
    );

    const runner = new CodexAgentRunner(
      new MemoryLogger(),
      (serviceConfig) =>
        new LinearClient(
          serviceConfig,
          async () => new Response(JSON.stringify({ data: { viewer: { id: 'user-1' } } }), { status: 200 }),
        ),
      () => fakeTransport,
    );

    await runner.run({
      issue,
      attempt: null,
      prompt: 'Do work',
      workspace: { path: process.cwd(), workspace_key: 'OTR-1', created_now: false },
      config,
    });

    expect(fakeTransport.responses).toEqual([
      {
        id: 'server-request-1',
        result: {
          success: true,
          contentItems: [{ type: 'inputText', text: JSON.stringify({ viewer: { id: 'user-1' } }, null, 2) }],
        },
      },
    ]);
  });
});
