import { Env } from '../index';

interface ServiceAccountKey {
  client_email: string;
  private_key: string;
  project_id: string;
}

export async function sendFcmMessage(
  env: Env,
  token: string,
  title: string,
  body: string,
  data?: Record<string, string>,
): Promise<void> {
  const serviceAccount: ServiceAccountKey = JSON.parse(env.FCM_SERVICE_ACCOUNT_KEY);
  const accessToken = await getAccessToken(serviceAccount);

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data: data ?? {},
          android: {
            priority: 'high',
            notification: { sound: 'default' },
          },
          apns: {
            payload: {
              aps: { sound: 'default', badge: 1 },
            },
          },
        },
      }),
    },
  );

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`FCM send failed: ${response.status} ${error}`);
  }
}

async function getAccessToken(serviceAccount: ServiceAccountKey): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = btoa(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const payload = btoa(JSON.stringify({
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }));

  const unsignedToken = `${header}.${payload}`;

  // Import private key and sign
  const keyData = serviceAccount.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\n/g, '');

  const key = await crypto.subtle.importKey(
    'pkcs8',
    Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0)),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsignedToken),
  );

  const signedToken = `${unsignedToken}.${btoa(String.fromCharCode(...new Uint8Array(signature)))}`;

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${signedToken}`,
  });

  const data = await response.json() as { access_token: string };
  return data.access_token;
}
