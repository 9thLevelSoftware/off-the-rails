import { spawn, type ChildProcessWithoutNullStreams } from 'node:child_process';
import readline from 'node:readline';
import type { AgentRunInput, AgentRunResult, LiveSession, Logger } from './types.js';
import type { LinearClient as LinearGraphQLClient } from './linear.js';

type JsonObject = Record<string, unknown>;

interface PendingRequest {
  resolve: (value: JsonObject) => void;
  reject: (error: Error) => void;
  timer: NodeJS.Timeout;
}

export interface AppServerTransport {
  start(command: string, cwd: string): void;
  stop(): Promise<void>;
  request(method: string, params: unknown, timeoutMs: number): Promise<JsonObject>;
  respond(id: string | number, result: unknown): void;
  notify(method: string, params?: unknown): void;
  onMessage(callback: (message: JsonObject) => void): void;
  readonly pid: number | null;
}

export class StdioAppServerTransport implements AppServerTransport {
  private child: ChildProcessWithoutNullStreams | null = null;
  private nextId = 1;
  private readonly pending = new Map<string | number, PendingRequest>();
  private callbacks: Array<(message: JsonObject) => void> = [];

  constructor(private readonly logger: Logger) {}

  get pid(): number | null {
    return this.child?.pid ?? null;
  }

  start(command: string, cwd: string): void {
    this.child = spawn(command, {
      cwd,
      shell: true,
      windowsHide: true,
      stdio: ['pipe', 'pipe', 'pipe'],
      env: process.env,
    });

    const reader = readline.createInterface({ input: this.child.stdout });
    reader.on('line', (line) => {
      if (!line.trim()) {
        return;
      }
      try {
        const message = JSON.parse(line) as JsonObject;
        this.handleMessage(message);
      } catch (error) {
        void this.logger.warn('codex.unparseable_stdout', {
          line,
          error: error instanceof Error ? error.message : String(error),
        });
      }
    });

    this.child.stderr.on('data', (chunk: Buffer) => {
      void this.logger.warn('codex.stderr', { message: chunk.toString('utf8') });
    });

    this.child.on('exit', (code, signal) => {
      const error = new Error(`Codex app-server exited with code=${code ?? 'null'} signal=${signal ?? 'null'}`);
      for (const pending of this.pending.values()) {
        clearTimeout(pending.timer);
        pending.reject(error);
      }
      this.pending.clear();
      void this.logger.warn('codex.exited', { code, signal });
    });
  }

  async stop(): Promise<void> {
    if (!this.child || this.child.killed) {
      return;
    }
    this.child.kill();
  }

  request(method: string, params: unknown, timeoutMs: number): Promise<JsonObject> {
    if (!this.child) {
      throw new Error('Codex app-server transport is not started');
    }
    const id = this.nextId++;
    const payload = { id, method, params };
    const promise = new Promise<JsonObject>((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`Timed out waiting for Codex response to ${method}`));
      }, timeoutMs);
      this.pending.set(id, { resolve, reject, timer });
    });

    this.child.stdin.write(`${JSON.stringify(payload)}\n`);
    return promise;
  }

  respond(id: string | number, result: unknown): void {
    if (!this.child) {
      throw new Error('Codex app-server transport is not started');
    }
    this.child.stdin.write(`${JSON.stringify({ id, result })}\n`);
  }

  notify(method: string, params?: unknown): void {
    if (!this.child) {
      throw new Error('Codex app-server transport is not started');
    }
    this.child.stdin.write(`${JSON.stringify(params === undefined ? { method } : { method, params })}\n`);
  }

  onMessage(callback: (message: JsonObject) => void): void {
    this.callbacks.push(callback);
  }

  private handleMessage(message: JsonObject): void {
    if ('id' in message && (message as { id: string | number }).id !== undefined && ('result' in message || 'error' in message)) {
      const id = (message as { id: string | number }).id;
      const pending = this.pending.get(id);
      if (pending) {
        clearTimeout(pending.timer);
        this.pending.delete(id);
        if ('error' in message) {
          pending.reject(new Error(JSON.stringify(message.error)));
        } else {
          pending.resolve((message.result ?? {}) as JsonObject);
        }
      }
    }

    for (const callback of this.callbacks) {
      callback(message);
    }
  }
}

export class CodexAgentRunner {
  private running = new Map<string, AppServerTransport>();

  constructor(
    private readonly logger: Logger,
    private readonly linearClientFactory: (config: AgentRunInput['config']) => LinearGraphQLClient,
    private readonly transportFactory: (logger: Logger) => AppServerTransport = (logger) => new StdioAppServerTransport(logger),
  ) {}

  async run(input: AgentRunInput): Promise<AgentRunResult> {
    const transport = this.transportFactory(this.logger);
    const liveSession = createEmptyLiveSession(String(transport.pid ?? ''));
    const linearClient = this.linearClientFactory(input.config);
    const pendingToolCalls = new Set<Promise<void>>();
    let turnCompleted = false;

    this.running.set(input.issue.id, transport);
    try {
      transport.onMessage((message) => {
        updateLiveSession(liveSession, message, Date.now());
        if (message.method === 'turn/completed') {
          turnCompleted = true;
        }
        if (message.method === 'item/tool/call') {
          const pending = this.handleDynamicToolRequest(transport, linearClient, message).finally(() => {
            pendingToolCalls.delete(pending);
          });
          pendingToolCalls.add(pending);
        }
      });

      transport.start(input.config.codex.command, input.workspace.path);
      liveSession.codex_app_server_pid = transport.pid === null ? null : String(transport.pid);

      await transport.request(
        'initialize',
        {
          clientInfo: { name: 'off-the-rails-symphony', title: 'Off The Rails Symphony', version: '0.1.0' },
          capabilities: { experimentalApi: true },
        },
        input.config.codex.read_timeout_ms,
      );
      transport.notify('initialized');

      const threadResponse = await transport.request(
        'thread/start',
        {
          cwd: input.workspace.path,
          approvalPolicy: input.config.codex.approval_policy,
          sandbox: input.config.codex.thread_sandbox,
          model: input.config.codex.model,
          config: input.config.codex.model_reasoning_effort
            ? { model_reasoning_effort: input.config.codex.model_reasoning_effort }
            : {},
          ephemeral: false,
          serviceName: 'off-the-rails-symphony',
          dynamicTools: [linearGraphqlToolSpec()],
          experimentalRawEvents: false,
          persistExtendedHistory: true,
        },
        input.config.codex.read_timeout_ms,
      );

      const threadId = readThreadId(threadResponse, liveSession.thread_id);
      liveSession.thread_id = threadId;

      await transport.request(
        'turn/start',
        {
          threadId,
          input: [{ type: 'text', text: input.prompt, text_elements: [] }],
          cwd: input.workspace.path,
          approvalPolicy: input.config.codex.approval_policy,
          sandboxPolicy: input.config.codex.turn_sandbox_policy,
          model: input.config.codex.model,
          effort: input.config.codex.model_reasoning_effort,
        },
        input.config.codex.read_timeout_ms,
      );

      await waitForTurnCompletion(() => turnCompleted, input.config.codex.turn_timeout_ms, input.config.codex.read_timeout_ms);
      await Promise.all(pendingToolCalls);
      return { status: 'succeeded', live_session: liveSession };
    } catch (error) {
      await this.logger.error('codex.run_failed', { issue: input.issue.identifier, error: toMessage(error) });
      return { status: 'failed', error: toMessage(error), live_session: liveSession };
    } finally {
      this.running.delete(input.issue.id);
      await transport.stop();
    }
  }

  async cancel(issueId: string, reason: string): Promise<void> {
    const transport = this.running.get(issueId);
    if (!transport) {
      return;
    }
    await this.logger.warn('codex.cancel', { issue_id: issueId, reason });
    await transport.stop();
    this.running.delete(issueId);
  }

  private async handleDynamicToolRequest(
    transport: AppServerTransport,
    linearClient: LinearGraphQLClient,
    message: JsonObject,
  ): Promise<void> {
    const requestId = message.id as string | number | undefined;
    const params = message.params as JsonObject | undefined;
    if (!requestId || !params || params.tool !== 'linear_graphql') {
      return;
    }

    try {
      const args = params.arguments as JsonObject;
      const query = typeof args.query === 'string' ? args.query : '';
      const variables =
        typeof args.variables === 'object' && args.variables !== null ? (args.variables as Record<string, unknown>) : {};
      const result = await linearClient.rawQuery(query, variables);
      transport.respond(requestId, {
        success: true,
        contentItems: [{ type: 'inputText', text: JSON.stringify(result, null, 2) }],
      });
    } catch (error) {
      transport.respond(requestId, {
        success: false,
        contentItems: [{ type: 'inputText', text: toMessage(error) }],
      });
      await this.logger.error('codex.linear_graphql_failed', { error: toMessage(error) });
    }
  }
}

export function linearGraphqlToolSpec(): JsonObject {
  return {
    namespace: 'linear',
    name: 'linear_graphql',
    description: 'Execute a Linear GraphQL query or mutation using the Symphony LINEAR_API_KEY.',
    inputSchema: {
      type: 'object',
      additionalProperties: false,
      required: ['query'],
      properties: {
        query: { type: 'string' },
        variables: {
          type: 'object',
          additionalProperties: true,
        },
      },
    },
  };
}

function createEmptyLiveSession(pid: string): LiveSession {
  return {
    session_id: '-',
    thread_id: '',
    turn_id: '',
    codex_app_server_pid: pid || null,
    last_codex_event: null,
    last_codex_timestamp: null,
    last_codex_message: null,
    codex_input_tokens: 0,
    codex_output_tokens: 0,
    codex_total_tokens: 0,
    last_reported_input_tokens: 0,
    last_reported_output_tokens: 0,
    last_reported_total_tokens: 0,
    turn_count: 0,
  };
}

function updateLiveSession(session: LiveSession, message: JsonObject, timestamp: number): void {
  const method = typeof message.method === 'string' ? message.method : null;
  session.last_codex_event = method;
  session.last_codex_timestamp = timestamp;
  session.last_codex_message = JSON.stringify(message).slice(0, 500);

  const params = message.params as JsonObject | undefined;
  if (params?.threadId && typeof params.threadId === 'string') {
    session.thread_id = params.threadId;
  }
  if (params?.turnId && typeof params.turnId === 'string') {
    session.turn_id = params.turnId;
  }
  if (method === 'turn/started') {
    session.turn_count += 1;
  }
  if (method === 'thread/tokenUsage/updated' && params) {
    const usage = params.usage as JsonObject | undefined;
    const input = numberFrom(usage?.inputTokens);
    const output = numberFrom(usage?.outputTokens);
    const total = numberFrom(usage?.totalTokens);
    session.codex_input_tokens = input;
    session.codex_output_tokens = output;
    session.codex_total_tokens = total;
    session.last_reported_input_tokens = input;
    session.last_reported_output_tokens = output;
    session.last_reported_total_tokens = total;
  }
  session.session_id = session.thread_id && session.turn_id ? `${session.thread_id}-${session.turn_id}` : '-';
}

function readThreadId(response: JsonObject, fallback: string): string {
  const thread = response.thread as JsonObject | undefined;
  if (thread && typeof thread.id === 'string') {
    return thread.id;
  }
  if (typeof response.threadId === 'string') {
    return response.threadId;
  }
  if (fallback) {
    return fallback;
  }
  throw new Error('Codex thread/start response did not include a thread id');
}

async function waitForTurnCompletion(isComplete: () => boolean, timeoutMs: number, pollMs: number): Promise<void> {
  const started = Date.now();
  while (!isComplete()) {
    if (Date.now() - started > timeoutMs) {
      throw new Error('Codex turn timed out');
    }
    await new Promise((resolve) => setTimeout(resolve, Math.min(pollMs, 100)));
  }
}

function numberFrom(value: unknown): number {
  return typeof value === 'number' ? value : 0;
}

function toMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}
