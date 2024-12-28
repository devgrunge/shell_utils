/**
 * src/json_transform_to_insomnia.ts
 *
 * Gera um arquivo de exportação para o Insomnia que cria subpastas
 * conforme o primeiro segmento da rota (ex.: /admin => pasta "Admin").
 */

import * as fs from 'fs';
import * as path from 'path';

/* =========================================
   1) Tipos do Insomnia
   ========================================= */

interface InsomniaBaseResource {
  _id: string;
  _type: string;
}

type InsomniaResource =
  | InsomniaWorkspace
  | InsomniaEnvironment
  | InsomniaRequestGroup
  | InsomniaRequest;

interface InsomniaExport {
  _type: 'export';
  __export_format: number;
  __export_date: string;
  __export_source: string;
  resources: InsomniaResource[];
}

interface InsomniaWorkspace extends InsomniaBaseResource {
  _type: 'workspace';
  name: string;
  description?: string;
  scope: 'collection' | 'environment';
}

interface InsomniaEnvironment extends InsomniaBaseResource {
  _type: 'environment';
  parentId: string;
  name: string;
  data: Record<string, unknown>;
  dataPropertyOrder: null | number;
  color?: string | null;
  isPrivate?: boolean;
  metaSortKey?: number;
}

interface InsomniaRequestGroup extends InsomniaBaseResource {
  _type: 'request_group';
  parentId: string;
  name: string;
  environment?: object;
  environmentPropertyOrder?: number | null;
  metaSortKey?: number;
}

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
   2) Objeto principal de export
   ========================================= */
const insomniaExport: InsomniaExport = {
  _type: 'export',
  __export_format: 4,
  __export_date: new Date().toISOString(),
  // Valor reconhecido pelo Insomnia
  __export_source: 'insomnia.desktop.app:v2023.5.8',
  resources: [],
};

/* =========================================
   3) Funções utilitárias
   ========================================= */
function generateId(prefix: string): string {
  return prefix + Math.random().toString(36).substring(2, 6) + Date.now().toString().substring(7);
}

/**
 * Extrai o primeiro segmento do path:
 * '/auth/signup' => 'auth'
 * '/payment/stripe/create-subscribe' => 'payment'
 * '/kago/delete-all-news' => 'kago'
 * '/*' => 'Wildcard' (caso especial)
 * Se não encontrar nada, retorna 'root'
 */
function getPrimarySegment(fullPath: string): string {
  // Ex: "/auth/signup" => [ '', 'auth', 'signup' ]
  if (!fullPath.startsWith('/')) {
    fullPath = '/' + fullPath;
  }
  const segments = fullPath.split('/'); // primeiro elemento é ''
  // segments[1] seria 'auth'
  const primary = segments[1] || '';

  // Tratar rota "/*" => vira 'Wildcard'
  if (primary === '*') {
    return 'Wildcard';
  }

  // Se vazio, retorna 'root'
  if (!primary) {
    return 'root';
  }

  return primary;
}

/**
 * Helper para dar capitalize no nome da pasta (opcional).
 * "auth" => "Auth", "admin" => "Admin", ...
 */
function capitalize(str: string): string {
  if (!str) return str;
  return str.charAt(0).toUpperCase() + str.slice(1);
}

/* =========================================
   4) Lista de rotas
   ========================================= */
interface RouteDefinition {
  path: string;
  methods: string[];
}

const routes: RouteDefinition[] = [
  {
    path: '/*',
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
  },
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
    path: '/auth/recovery-email',
    methods: ['POST'],
  },
  {
    path: '/auth/signout',
    methods: ['GET'],
  },
  {
    path: '/auth/delete-email/:email',
    methods: ['DELETE'],
  },
  {
    path: '/cliente',
    methods: ['POST', 'GET'],
  },
  {
    path: '/cliente/:id',
    methods: ['GET', 'PATCH', 'DELETE'],
  },
  {
    path: '/health',
    methods: ['GET'],
  },
  {
    path: '/admin',
    methods: ['POST', 'GET'],
  },
  {
    path: '/admin/:id',
    methods: ['GET', 'PATCH', 'DELETE'],
  },
  {
    path: '/paypal/payment',
    methods: ['POST'],
  },
  {
    path: '/payment/stripe/create-subscribe',
    methods: ['POST'],
  },
  {
    path: '/payment/stripe/create-customer',
    methods: ['POST'],
  },
  {
    path: '/payment/stripe/list-products',
    methods: ['GET'],
  },
  {
    path: '/payment/stripe/portal-session',
    methods: ['POST'],
  },
  {
    path: '/payment/stripe/edit-subscription',
    methods: ['POST'],
  },
  {
    path: '/payment/stripe/cancel-subscription',
    methods: ['DELETE'],
  },
  {
    path: '/payment/stripe/list-subscriptions',
    methods: ['GET'],
  },
  {
    path: '/payment/stripe/success',
    methods: ['GET'],
  },
  {
    path: '/payment/stripe/customer',
    methods: ['PUT', 'GET', 'DELETE'],
  },
  {
    path: '/payment/stripe/mass-customers',
    methods: ['GET'],
  },
  {
    path: '/webhook',
    methods: ['POST'],
  },
  {
    path: '/legal-assistant',
    methods: ['POST', 'GET'],
  },
  {
    path: '/legal-assistant/:id',
    methods: ['GET', 'PATCH', 'DELETE'],
  },
  {
    path: '/whatsapp',
    methods: ['POST', 'GET'],
  },
  {
    path: '/whatsapp/:id',
    methods: ['GET', 'PATCH', 'DELETE'],
  },
  {
    path: '/kago',
    methods: ['GET'],
  },
  {
    path: '/kago/push-notification',
    methods: ['POST'],
  },
  {
    path: '/kago/delete-all-news',
    methods: ['GET'],
  },
  {
    path: '/address',
    methods: ['POST', 'GET'],
  },
  {
    path: '/address/:id',
    methods: ['GET', 'PATCH', 'DELETE'],
  },
];

/* =========================================
   5) Criar workspace e environment base
   ========================================= */
const workspaceId = generateId('wrk_');
const workspace: InsomniaWorkspace = {
  _id: workspaceId,
  _type: 'workspace',
  name: 'NestJS Routes',
  description: 'Workspace gerado automaticamente',
  scope: 'collection',
};
insomniaExport.resources.push(workspace);

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
   6) Criar pastas dinamicamente
   ========================================= */

/**
 * Mapa: prefix -> ID da pasta
 * Ex.: 'auth' => 'fld_abcd123'
 */
const folderMap: Record<string, string> = {};

/**
 * Função que retorna o ID da pasta de um prefixo,
 * criando a pasta se não existir ainda.
 */
function getOrCreateFolderForPrefix(prefix: string): string {
  if (folderMap[prefix]) {
    return folderMap[prefix];
  }
  // criar folder
  const folderId = generateId('fld_');
  const folder: InsomniaRequestGroup = {
    _id: folderId,
    _type: 'request_group',
    parentId: workspaceId,
    name: capitalize(prefix), // Pasta com a primeira letra maiúscula
    environment: {},
    environmentPropertyOrder: null,
    metaSortKey: -1,
  };
  insomniaExport.resources.push(folder);
  folderMap[prefix] = folderId;
  return folderId;
}

/* =========================================
   7) Gerar requests conforme a rota
   ========================================= */
routes.forEach(({ path, methods }) => {
  const primarySegment = getPrimarySegment(path); // ex: "/auth/xxx" => "auth"

  // Obter ID da pasta correspondente
  const folderId = getOrCreateFolderForPrefix(primarySegment);

  // Criar cada request
  methods.forEach((method) => {
    const requestId = generateId('req_');
    const request: InsomniaRequest = {
      _id: requestId,
      _type: 'request',
      parentId: folderId,
      name: `[${method}] ${path}`,
      method: method.toUpperCase(),
      url: `http://localhost:3000${path}`, // Ajustar se quiser outra base
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
   8) Salvar arquivo insomnia-export.json
   ========================================= */
const outputFilePath = path.join(__dirname, 'insomnia-export.json');
fs.writeFileSync(outputFilePath, JSON.stringify(insomniaExport, null, 2), 'utf8');

console.log(`\nInsomnia export created at:\n  ${outputFilePath}\n`);
console.log(`Import this file into Insomnia -> Application -> Import/Export -> Import Data -> From File.\n`);