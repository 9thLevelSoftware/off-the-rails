import { appendFileSync, mkdirSync } from 'node:fs';
import path from 'node:path';
import type { Logger } from './types.js';

type Level = 'debug' | 'info' | 'warn' | 'error';

export class JsonlLogger implements Logger {
  private readonly filePath: string;

  constructor(logsRoot: string, fileName = 'symphony.jsonl') {
    mkdirSync(logsRoot, { recursive: true });
    this.filePath = path.join(logsRoot, fileName);
  }

  debug(event: string, fields: Record<string, unknown> = {}): void {
    this.write('debug', event, fields);
  }

  info(event: string, fields: Record<string, unknown> = {}): void {
    this.write('info', event, fields);
  }

  warn(event: string, fields: Record<string, unknown> = {}): void {
    this.write('warn', event, fields);
  }

  error(event: string, fields: Record<string, unknown> = {}): void {
    this.write('error', event, fields);
  }

  private write(level: Level, event: string, fields: Record<string, unknown>): void {
    appendFileSync(
      this.filePath,
      `${JSON.stringify({
        ts: new Date().toISOString(),
        level,
        event,
        ...fields,
      })}\n`,
      'utf8',
    );
  }
}

export class ConsoleLogger implements Logger {
  debug(event: string, fields: Record<string, unknown> = {}): void {
    this.write('debug', event, fields);
  }

  info(event: string, fields: Record<string, unknown> = {}): void {
    this.write('info', event, fields);
  }

  warn(event: string, fields: Record<string, unknown> = {}): void {
    this.write('warn', event, fields);
  }

  error(event: string, fields: Record<string, unknown> = {}): void {
    this.write('error', event, fields);
  }

  private write(level: Level, event: string, fields: Record<string, unknown>): void {
    const line = JSON.stringify({
      ts: new Date().toISOString(),
      level,
      event,
      ...fields,
    });
    if (level === 'error') {
      console.error(line);
    } else {
      console.log(line);
    }
  }
}

export class MemoryLogger implements Logger {
  readonly entries: Array<{ level: Level; event: string; fields: Record<string, unknown> }> = [];

  debug(event: string, fields: Record<string, unknown> = {}): void {
    this.entries.push({ level: 'debug', event, fields });
  }

  info(event: string, fields: Record<string, unknown> = {}): void {
    this.entries.push({ level: 'info', event, fields });
  }

  warn(event: string, fields: Record<string, unknown> = {}): void {
    this.entries.push({ level: 'warn', event, fields });
  }

  error(event: string, fields: Record<string, unknown> = {}): void {
    this.entries.push({ level: 'error', event, fields });
  }
}
