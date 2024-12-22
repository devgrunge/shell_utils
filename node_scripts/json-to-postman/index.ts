/**
 * src/json_transform_to_insomnia.ts
 *
 * Script in TypeScript to generate an Insomnia export JSON from a list of routes.
 */

import * as fs from 'fs';
import * as path from 'path';

/* =========================================
   1) Define the Insomnia data types
   ========================================= */

interface InsomniaBaseResource {
  _id: string;
  _type: string;
}

interface InsomniaExport {
  _type: 'export';
  __export_format: number;
  __export_date: string;
  __export_source: string;
  resources: InsomniaResource[];
}

// Union type for any resource in the export
type InsomniaResource =
  | InsomniaWorkspace
  | InsomniaEnvironment
  | InsomniaRequestGroup
  | InsomniaRequest;

/**
 * A workspace is typically the parent container for all requests/folders/environments.
 */
interface InsomniaWorkspace extends InsomniaBaseResource {
  _type: 'workspace';
  name: string;
  description?: string;
  scope: 'collection' | 'environment';
}

/**
 * Environments in Insomnia. Usually there's a base environment at the workspace level.
 */
interface InsomniaEnvironment extends InsomniaBaseResource {
  _type: 'environment';
  parentId: string; // Usually the workspace ID
  name: string;
  data: Record<string, unknown>;
  dataPropertyOrder: null | number;
  color?: string | null;
  isPrivate?: boolean;
  metaSortKey?: number;
}

/**
 * A request group is essentially a folder of requests.
 */
interface InsomniaRequestGroup extends InsomniaBaseResource {
  _type: 'request_group';
  parentId: string;
  name: string;
  // Optional extras
  environment?: object;
  environmentPropertyOrder?: number | null;
  metaSortKey?: number;
}

/**
 * A single request.
 */
interface InsomniaRequest extends InsomniaBaseResource {
  _type: 'request';
  parentId: string;
  name: string;
  method: string;
  url: string;
  body: any;
  headers: Array<{ name: string; value: string }>;
  authentication: any;
  metaSortKey: number;
  isPrivate: boolean;
  settingStoreCookies: boolean;
  settingSendCookies: boolean;
  settingDisableRenderRequestBody: boolean;
  settingEncodeUrl: boolean;
  settingRebuildPath: boolean;
  settingFollowRedirects: 'global' | 'off';
}

/* =========================================
   2) Build the main export skeleton
   ========================================= */
const insomniaExport: InsomniaExport = {
  _type: 'export',
  __export_format: 4,
  __export_date: new Date().toISOString(),
  // Use a source that Insomnia recognizes. The exact value is flexible,
  // but it's often helpful to look like an Insomnia version.
  __export_source: 'insomnia.desktop.app:v2023.5.8',
  resources: [],
};

/**
 * Generate a random ID for each resource
 */
function generateId(prefix: string): string {
  return prefix + Math.random().toString(36).substring(2, 6) + Date.now().toString().substring(7);
}

/* =========================================
   3) Define the routes you want
   ========================================= */
interface RouteDefinition {
  path: string;
  methods: string[];
}

const routes: RouteDefinition[] = [
  {
    path: '/open-ai',
    methods: ['POST', 'GET'],
  },
  {
    path: '/open-ai/:id',
    methods: ['GET', 'PATCH', 'DELETE'],
  },
  {
    path: '/auth/signin',
    methods: ['POST'],
  },
  {
    path: '/auth/signup',
    methods: ['POST'],
  },
  {
    path: '/health',
    methods: ['GET'],
  },
  // Add more routes as needed...
];

/* =========================================
   4) Create a workspace resource
   ========================================= */
const workspaceId = generateId('wrk_');
const workspace: InsomniaWorkspace = {
  _id: workspaceId,
  _type: 'workspace',
  name: 'NestJS Routes',
  description: 'Generated workspace for NestJS routes',
  scope: 'collection',
};
insomniaExport.resources.push(workspace);

/* =========================================
   5) Create a base environment resource
      (Needed so Insomnia recognizes format)
   ========================================= */
const baseEnvironmentId = generateId('env_');
const baseEnvironment: InsomniaEnvironment = {
  _id: baseEnvironmentId,
  _type: 'environment',
  parentId: workspaceId,
  name: 'Base Environment',
  data: {},
  dataPropertyOrder: null,
  color: null,
  isPrivate: false,
  metaSortKey: Date.now(),
};
insomniaExport.resources.push(baseEnvironment);

/* =========================================
   6) Create a request group (folder)
   ========================================= */
const folderId = generateId('fld_');
const folder: InsomniaRequestGroup = {
  _id: folderId,
  _type: 'request_group',
  parentId: workspaceId,
  name: 'Automated Routes',
  environment: {},
  environmentPropertyOrder: null,
  metaSortKey: -1,
};
insomniaExport.resources.push(folder);

/* =========================================
   7) Generate each request from our routes
   ========================================= */
routes.forEach(({ path, methods }) => {
  methods.forEach((method) => {
    const requestId = generateId('req_');
    const request: InsomniaRequest = {
      _id: requestId,
      _type: 'request',
      parentId: folderId,
      name: `[${method}] ${path}`,
      method: method.toUpperCase(),
      url: `http://localhost:3000${path}`, // Adjust base URL as needed
      body: {},
      headers: [],
      authentication: {},
      metaSortKey: -1,
      isPrivate: false,
      settingStoreCookies: true,
      settingSendCookies: true,
      settingDisableRenderRequestBody: false,
      settingEncodeUrl: true,
      settingRebuildPath: true,
      settingFollowRedirects: 'global',
    };
    insomniaExport.resources.push(request);
  });
});

/* =========================================
   8) Write the final JSON to a file
   ========================================= */
const outputFilePath = path.join(__dirname, 'insomnia-export.json');

fs.writeFileSync(outputFilePath, JSON.stringify(insomniaExport, null, 2), 'utf8');

console.log(`\nInsomnia export created at:\n  ${outputFilePath}\n`);
console.log(`Import this file into Insomnia via Application -> Import/Export -> Import Data.`);