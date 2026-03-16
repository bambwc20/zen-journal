import { Env, jsonResponse } from '../index';
import { sendFcmMessage } from '../lib/fcm';

export async function handlePush(request: Request, env: Env): Promise<Response> {
  const url = new URL(request.url);
  const path = url.pathname.replace('/api/push', '');

  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  if (path === '/send') {
    const body = await request.json() as {
      segment?: string;
      title: string;
      body: string;
    };

    let query = 'SELECT fcm_token FROM user_profiles WHERE fcm_token IS NOT NULL';
    const bindings: string[] = [];

    if (body.segment) {
      query += ' AND segments = ?';
      bindings.push(body.segment);
    }

    const stmt = bindings.length > 0
      ? env.DB.prepare(query).bind(...bindings)
      : env.DB.prepare(query);

    const results = await stmt.all<{ fcm_token: string }>();
    const tokens = results.results.map((r) => r.fcm_token).filter(Boolean);

    let sentCount = 0;
    for (const token of tokens) {
      try {
        await sendFcmMessage(env, token, body.title, body.body);
        sentCount++;
      } catch (e) {
        console.error(`Failed to send to ${token}:`, e);
      }
    }

    // Log push
    await env.DB.prepare(
      'INSERT INTO push_log (target_segment, title, body, sent_count) VALUES (?, ?, ?, ?)'
    ).bind(body.segment ?? 'all', body.title, body.body, sentCount).run();

    return jsonResponse({ sent: sentCount, total: tokens.length });
  }

  return jsonResponse({ error: 'Not Found' }, 404);
}
