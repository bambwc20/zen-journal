import { Env, jsonResponse } from '../index';
import { sendFcmMessage } from '../lib/fcm';

interface RevenueCatEvent {
  type: string;
  app_user_id: string;
  product_id?: string;
  expiration_at_ms?: number;
}

interface RevenueCatWebhookBody {
  event: RevenueCatEvent;
}

export async function handleWebhook(request: Request, env: Env): Promise<Response> {
  if (request.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  // Verify webhook secret
  const authHeader = request.headers.get('Authorization');
  if (authHeader !== `Bearer ${env.REVENUECAT_WEBHOOK_SECRET}`) {
    return jsonResponse({ error: 'Unauthorized' }, 401);
  }

  const body = await request.json() as RevenueCatWebhookBody;
  const event = body.event;
  const uid = event.app_user_id;

  switch (event.type) {
    case 'INITIAL_PURCHASE':
    case 'NON_RENEWING_PURCHASE': {
      await env.DB.prepare(
        "UPDATE user_profiles SET segments = 'premium' WHERE firebase_uid = ?"
      ).bind(uid).run();
      break;
    }
    case 'CANCELLATION': {
      await env.DB.prepare(
        "UPDATE user_profiles SET segments = 'churned' WHERE firebase_uid = ?"
      ).bind(uid).run();
      break;
    }
    case 'EXPIRATION': {
      await env.DB.prepare(
        "UPDATE user_profiles SET segments = 'free' WHERE firebase_uid = ?"
      ).bind(uid).run();
      // Send expiration push
      const user = await env.DB.prepare(
        'SELECT fcm_token FROM user_profiles WHERE firebase_uid = ?'
      ).bind(uid).first<{ fcm_token: string }>();
      if (user?.fcm_token) {
        await sendFcmMessage(
          env,
          user.fcm_token,
          '구독이 만료되었습니다',
          '프리미엄 기능을 계속 이용하려면 구독을 갱신해주세요.',
        );
      }
      break;
    }
    case 'BILLING_ISSUE': {
      const user = await env.DB.prepare(
        'SELECT fcm_token FROM user_profiles WHERE firebase_uid = ?'
      ).bind(uid).first<{ fcm_token: string }>();
      if (user?.fcm_token) {
        await sendFcmMessage(
          env,
          user.fcm_token,
          '결제 오류',
          '구독 결제에 문제가 발생했습니다. 결제 정보를 확인해주세요.',
        );
      }
      break;
    }
    case 'RENEWAL':
    default:
      // Log only
      break;
  }

  return jsonResponse({ success: true });
}
