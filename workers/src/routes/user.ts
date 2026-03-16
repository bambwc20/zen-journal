import { Env, jsonResponse } from '../index';
import { verifyFirebaseToken } from '../lib/auth';

export async function handleUser(request: Request, env: Env): Promise<Response> {
  const url = new URL(request.url);
  const path = url.pathname.replace('/api/user', '');

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
    case 'GET': {
      if (path === '/profile') {
        const result = await env.DB.prepare(
          'SELECT * FROM user_profiles WHERE firebase_uid = ?'
        ).bind(uid).first();
        if (!result) {
          return jsonResponse({ error: 'Profile not found' }, 404);
        }
        return jsonResponse(result);
      }
      break;
    }
    case 'POST': {
      if (path === '/register') {
        const body = await request.json() as Record<string, string>;
        await env.DB.prepare(
          `INSERT INTO user_profiles (firebase_uid, fcm_token, device_os, utm_source, utm_medium)
           VALUES (?, ?, ?, ?, ?)
           ON CONFLICT(firebase_uid) DO UPDATE SET
             fcm_token = excluded.fcm_token,
             device_os = excluded.device_os,
             last_online_at = unixepoch()`
        ).bind(
          uid,
          body.fcm_token ?? null,
          body.device_os ?? null,
          body.utm_source ?? null,
          body.utm_medium ?? null,
        ).run();
        return jsonResponse({ success: true });
      }
      break;
    }
    case 'PUT': {
      if (path === '/fcm-token') {
        const body = await request.json() as { fcm_token: string };
        await env.DB.prepare(
          'UPDATE user_profiles SET fcm_token = ?, last_online_at = unixepoch() WHERE firebase_uid = ?'
        ).bind(body.fcm_token, uid).run();
        return jsonResponse({ success: true });
      }
      break;
    }
  }

  return jsonResponse({ error: 'Not Found' }, 404);
}
