import type { Issue, IssueTracker, ServiceConfig } from './types.js';

export interface GraphQLResponse<T> {
  data?: T;
  errors?: Array<{ message: string; path?: Array<string | number>; extensions?: Record<string, unknown> }>;
}

export type FetchLike = (input: string, init: RequestInit) => Promise<Response>;

interface LinearIssueNode {
  id?: string | null;
  identifier?: string | null;
  title?: string | null;
  description?: string | null;
  priority?: number | null;
  branchName?: string | null;
  url?: string | null;
  createdAt?: string | null;
  updatedAt?: string | null;
  state?: { name?: string | null } | null;
  labels?: { nodes?: Array<{ name?: string | null }> | null } | null;
  relations?: {
    nodes?: Array<{
      type?: string | null;
      relatedIssue?: LinearIssueNode | null;
      issue?: LinearIssueNode | null;
    }> | null;
  } | null;
}

interface IssuesPage {
  issues: {
    nodes: LinearIssueNode[];
    pageInfo: {
      hasNextPage: boolean;
      endCursor: string | null;
    };
  };
}

export class LinearClient implements IssueTracker {
  constructor(
    private readonly config: ServiceConfig,
    private readonly fetchImpl: FetchLike = globalThis.fetch.bind(globalThis),
  ) {}

  async rawQuery<T = unknown>(query: string, variables: Record<string, unknown> = {}): Promise<T> {
    if (!this.config.tracker.api_key) {
      throw new Error('LINEAR_API_KEY is required for Linear GraphQL calls');
    }

    const response = await this.fetchImpl(this.config.tracker.endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: this.config.tracker.api_key,
      },
      body: JSON.stringify({ query, variables }),
    });

    if (!response.ok) {
      throw new Error(`Linear GraphQL HTTP ${response.status}: ${await response.text()}`);
    }

    const payload = (await response.json()) as GraphQLResponse<T>;
    if (payload.errors && payload.errors.length > 0) {
      throw new Error(`Linear GraphQL error: ${payload.errors.map((error) => error.message).join('; ')}`);
    }
    if (payload.data === undefined) {
      throw new Error('Linear GraphQL response did not include data');
    }

    return payload.data;
  }

  async fetchCandidateIssues(activeStates: string[]): Promise<Issue[]> {
    return this.fetchIssuesByStates(activeStates);
  }

  async fetchTerminalIssues(terminalStates: string[]): Promise<Issue[]> {
    return this.fetchIssuesByStates(terminalStates);
  }

  async fetchIssuesByIds(ids: string[]): Promise<Issue[]> {
    if (ids.length === 0) {
      return [];
    }

    const data = await this.rawQuery<IssuesPage>(ISSUES_BY_IDS_QUERY, {
      ids,
      first: 100,
    });

    return normalizeIssueNodes(data.issues.nodes);
  }

  private async fetchIssuesByStates(states: string[]): Promise<Issue[]> {
    if (!this.config.tracker.project_slug) {
      throw new Error('LINEAR_PROJECT_SLUG is required for Linear issue polling');
    }

    const issues: Issue[] = [];
    let after: string | null = null;

    do {
      const data: IssuesPage = await this.rawQuery<IssuesPage>(ISSUES_BY_PROJECT_AND_STATE_QUERY, {
        projectSlug: this.config.tracker.project_slug,
        states,
        first: 50,
        after,
      });

      issues.push(...normalizeIssueNodes(data.issues.nodes));
      after = data.issues.pageInfo.hasNextPage ? data.issues.pageInfo.endCursor : null;
    } while (after);

    return issues;
  }
}

export function normalizeIssueNodes(nodes: LinearIssueNode[]): Issue[] {
  return nodes.flatMap((node) => {
    if (!node.id || !node.identifier || !node.title || !node.state?.name) {
      return [];
    }

    return [
      {
        id: node.id,
        identifier: node.identifier,
        title: node.title,
        description: node.description ?? null,
        priority: typeof node.priority === 'number' && node.priority > 0 ? node.priority : null,
        state: node.state.name,
        branch_name: node.branchName ?? null,
        url: node.url ?? null,
        labels: (node.labels?.nodes ?? [])
          .map((label) => label.name)
          .filter((name): name is string => typeof name === 'string')
          .map((name) => name.toLowerCase()),
        blocked_by: (node.relations?.nodes ?? [])
          .filter((relation) => isBlockerRelation(relation.type))
          .map((relation) => relation.relatedIssue ?? relation.issue ?? null)
          .filter((related): related is LinearIssueNode => related !== null)
          .map((related) => ({
            id: related.id ?? null,
            identifier: related.identifier ?? null,
            state: related.state?.name ?? null,
            created_at: related.createdAt ?? null,
            updated_at: related.updatedAt ?? null,
          })),
        created_at: node.createdAt ?? null,
        updated_at: node.updatedAt ?? null,
      },
    ];
  });
}

function isBlockerRelation(type: string | null | undefined): boolean {
  if (!type) {
    return false;
  }
  const normalized = type.toLowerCase();
  return normalized === 'blocked_by' || normalized === 'blocks' || normalized === 'blockedby';
}

const ISSUE_FIELDS = `
  id
  identifier
  title
  description
  priority
  branchName
  url
  createdAt
  updatedAt
  state {
    name
  }
  labels {
    nodes {
      name
    }
  }
  relations {
    nodes {
      type
      relatedIssue {
        id
        identifier
        createdAt
        updatedAt
        state {
          name
        }
      }
      issue {
        id
        identifier
        createdAt
        updatedAt
        state {
          name
        }
      }
    }
  }
`;

export const ISSUES_BY_PROJECT_AND_STATE_QUERY = `
  query SymphonyIssuesByProjectAndState($projectSlug: String!, $states: [String!], $first: Int!, $after: String) {
    issues(
      first: $first
      after: $after
      filter: {
        project: { slug: { eq: $projectSlug } }
        state: { name: { in: $states } }
      }
    ) {
      nodes {
        ${ISSUE_FIELDS}
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

export const ISSUES_BY_IDS_QUERY = `
  query SymphonyIssuesByIds($ids: [String!], $first: Int!) {
    issues(first: $first, filter: { id: { in: $ids } }) {
      nodes {
        ${ISSUE_FIELDS}
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;
