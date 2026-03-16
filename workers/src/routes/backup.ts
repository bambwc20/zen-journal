import { Env, jsonResponse } from '../index';
import { verifyFirebaseToken } from '../lib/auth';

export async function handleBackup(request: Request, env: Env): Promise<Response> {
  const url = new URL(request.url);
  const path = url.pathname.replace('/api/backup', '');

  // Verify Firebase Auth token
  const authHeader = request.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return jsonResponse({ error: 'Unauthorized' }, 401);
  }
  const token = authHeader.slice(7);
  const uid = await verifyFirebaseToken(token);
  if (!uid) {
    return jsonResponse({ error: 'Invalid token' }, 401);
  }

  switch (request.method) {
    case 'POST': {
      // Upload backup
      if (path === '/upload') {
        const body = await request.arrayBuffer();
        const key = `${uid}/${Date.now()}.sqlite.enc`;
        await env.BACKUP_BUCKET.put(key, body, {
          customMetadata: { uid, timestamp: Date.now().toString() },
        });
        return jsonResponse({ key, size: body.byteLength });
      }
      break;
    }
    case 'GET': {
      // Download latest backup
      if (path === '/download') {
        const list = await env.BACKUP_BUCKET.list({ prefix: `${uid}/` });
        if (list.objects.length === 0) {
          return jsonResponse({ error: 'No backups found' }, 404);
        }
        const latest = list.objects.sort((a, b) =>
          (b.uploaded?.getTime() ?? 0) - (a.uploaded?.getTime() ?? 0)
        )[0];
        const object = await env.BACKUP_BUCKET.get(latest.key);
        if (!object) {
          return jsonResponse({ error: 'Backup not found' }, 404);
        }
        return new Response(object.body, {
          headers: {
            'Content-Type': 'application/octet-stream',
            'Content-Disposition': `attachment; filename="backup.sqlite.enc"`,
          },
        });
      }
      // List backups
      if (path === '/list') {
        const list = await env.BACKUP_BUCKET.list({ prefix: `${uid}/` });
        const backups = list.objects.map((obj) => ({
          key: obj.key,
          size: obj.size,
          uploaded: obj.uploaded?.toISOString(),
        }));
        return jsonResponse({ backups });
      }
      break;
    }
  }

  return jsonResponse({ error: 'Not Found' }, 404);
}
