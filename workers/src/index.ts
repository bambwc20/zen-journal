import { handleBackup } from './routes/backup';
import { handleUser } from './routes/user';
import { handlePush } from './routes/push';
import { handleWebhook } from './routes/webhook';
import { handleScheduled } from './cron/scheduled';

export interface Env {
  DB: D1Database;
  BACKUP_BUCKET: R2Bucket;
  REVENUECAT_WEBHOOK_SECRET: string;
  FCM_SERVICE_ACCOUNT_KEY: string;
  ENVIRONMENT: string;
}

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;

    // CORS
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
      });
    }

    try {
      // Route matching
      if (path.startsWith('/api/backup')) {
        return handleBackup(request, env);
      }
      if (path.startsWith('/api/user')) {
        return handleUser(request, env);
      }
      if (path.startsWith('/api/push')) {
        return handlePush(request, env);
      }
      if (path.startsWith('/webhook/revenuecat')) {
        return handleWebhook(request, env);
      }

      // Health check
      if (path === '/health') {
        return jsonResponse({ status: 'ok', timestamp: Date.now() });
      }

      return jsonResponse({ error: 'Not Found' }, 404);
    } catch (error) {
      console.error('Unhandled error:', error);
      return jsonResponse({ error: 'Internal Server Error' }, 500);
    }
  },

  async scheduled(event: ScheduledEvent, env: Env, ctx: ExecutionContext): Promise<void> {
    ctx.waitUntil(handleScheduled(event, env));
  },
};

export function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
  });
}
