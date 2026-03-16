import { Env } from '../index';
import { sendFcmMessage } from '../lib/fcm';

export async function handleScheduled(event: ScheduledEvent, env: Env): Promise<void> {
  const day = new Date(event.scheduledTime).getUTCDay();

  if (day === 5) {
    // Friday - engagement push
    await sendSegmentPush(env, 'all', '이번 주도 수고했어요!', '앱에서 이번 주 기록을 확인해보세요.');
  } else if (day === 6) {
    // Saturday - premium promo
    await sendSegmentPush(env, 'free', '프리미엄 할인 중!', '지금 업그레이드하면 특별 혜택을 받으세요.');
  }
}

async function sendSegmentPush(
  env: Env,
  segment: string,
  title: string,
  body: string,
): Promise<void> {
  let query = 'SELECT fcm_token FROM user_profiles WHERE fcm_token IS NOT NULL';
  if (segment !== 'all') {
    query += ` AND segments = '${segment}'`;
  }

  const results = await env.DB.prepare(query).all<{ fcm_token: string }>();
  let sentCount = 0;

  for (const row of results.results) {
    if (row.fcm_token) {
      try {
        await sendFcmMessage(env, row.fcm_token, title, body);
        sentCount++;
      } catch (e) {
        console.error('Push failed:', e);
      }
    }
  }

  await env.DB.prepare(
    'INSERT INTO push_log (target_segment, title, body, sent_count) VALUES (?, ?, ?, ?)'
  ).bind(segment, title, body, sentCount).run();
}
