#!/usr/bin/env node
import path from 'node:path';
import { CodexAgentRunner } from './codexRunner.js';
import { ConsoleLogger, JsonlLogger } from './logger.js';
import { LinearClient } from './linear.js';
import { Orchestrator } from './orchestrator.js';

interface CliArgs {
  workflowPath: string;
  logsRoot: string | null;
  once: boolean;
  dryRun: boolean;
}

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));
  const consoleLogger = new ConsoleLogger();
  const logger = args.logsRoot ? new JsonlLogger(path.resolve(args.logsRoot)) : consoleLogger;
  const runner = new CodexAgentRunner(logger, (config) => new LinearClient(config));
  const orchestrator = new Orchestrator({
    workflowPath: args.workflowPath,
    dryRun: args.dryRun,
    once: args.once,
    logger,
    runner,
  });

  await orchestrator.start();
}

export function parseArgs(argv: string[]): CliArgs {
  const result: CliArgs = {
    workflowPath: 'WORKFLOW.md',
    logsRoot: null,
    once: false,
    dryRun: false,
  };

  const positional: string[] = [];
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === '--once') {
      result.once = true;
    } else if (arg === '--dry-run') {
      result.dryRun = true;
    } else if (arg === '--logs-root') {
      const value = argv[index + 1];
      if (!value) {
        throw new Error('--logs-root requires a path');
      }
      result.logsRoot = value;
      index += 1;
    } else if (arg.startsWith('--logs-root=')) {
      result.logsRoot = arg.slice('--logs-root='.length);
    } else if (arg.startsWith('--')) {
      throw new Error(`Unknown option: ${arg}`);
    } else {
      positional.push(arg);
    }
  }

  if (positional.length > 1) {
    throw new Error(`Expected at most one workflow path, got: ${positional.join(', ')}`);
  }
  result.workflowPath = positional[0] ?? result.workflowPath;
  return result;
}

main().catch((error) => {
  console.error(error instanceof Error ? error.stack : String(error));
  process.exitCode = 1;
});
