import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { Liquid } from 'liquidjs';
import YAML from 'yaml';
import type { Issue, WorkflowDefinition } from './types.js';

export class WorkflowError extends Error {
  constructor(
    public readonly code:
      | 'missing_workflow_file'
      | 'workflow_parse_error'
      | 'workflow_front_matter_not_a_map'
      | 'template_parse_error'
      | 'template_render_error',
    message: string,
    public readonly cause?: unknown,
  ) {
    super(message);
    this.name = 'WorkflowError';
  }
}

export async function loadWorkflow(workflowPath: string): Promise<WorkflowDefinition> {
  const absolutePath = path.resolve(workflowPath);
  let content: string;

  try {
    content = await readFile(absolutePath, 'utf8');
  } catch (error) {
    throw new WorkflowError('missing_workflow_file', `Unable to read workflow file: ${absolutePath}`, error);
  }

  return parseWorkflowContent(content, absolutePath);
}

export function parseWorkflowContent(content: string, workflowPath = 'WORKFLOW.md'): WorkflowDefinition {
  const normalized = content.replace(/^\uFEFF/, '');
  const lines = normalized.split(/\r?\n/);
  let rawFrontMatter = '';
  let body = normalized;

  if (lines[0]?.trim() === '---') {
    const closingIndex = lines.findIndex((line, index) => index > 0 && line.trim() === '---');
    if (closingIndex === -1) {
      throw new WorkflowError('workflow_parse_error', `Missing closing front matter marker in ${workflowPath}`);
    }

    rawFrontMatter = lines.slice(1, closingIndex).join('\n');
    body = lines.slice(closingIndex + 1).join('\n');
  }

  let config: Record<string, unknown> = {};
  if (rawFrontMatter.trim().length > 0) {
    try {
      const parsed = YAML.parse(rawFrontMatter) as unknown;
      if (!isPlainObject(parsed)) {
        throw new WorkflowError(
          'workflow_front_matter_not_a_map',
          `Workflow front matter must be a YAML object in ${workflowPath}`,
        );
      }
      config = parsed;
    } catch (error) {
      if (error instanceof WorkflowError) {
        throw error;
      }
      throw new WorkflowError('workflow_parse_error', `Unable to parse workflow YAML in ${workflowPath}`, error);
    }
  }

  return {
    config,
    prompt_template: body.trim(),
    path: path.resolve(workflowPath),
  };
}

export interface PromptContext {
  issue: Issue;
  attempt: number | null;
}

export async function renderPrompt(template: string, context: PromptContext): Promise<string> {
  const effectiveTemplate = template.trim() || 'You are working on an issue from Linear.';
  const engine = new Liquid({
    strictVariables: true,
    strictFilters: true,
  });

  try {
    engine.parse(effectiveTemplate);
  } catch (error) {
    throw new WorkflowError('template_parse_error', 'Workflow prompt template could not be parsed', error);
  }

  try {
    return await engine.parseAndRender(effectiveTemplate, context);
  } catch (error) {
    throw new WorkflowError('template_render_error', 'Workflow prompt template could not be rendered', error);
  }
}

function isPlainObject(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
