export async function verifyFirebaseToken(token: string): Promise<string | null> {
  try {
    // Decode JWT without verification for now (Firebase Admin SDK not available in Workers)
    // In production, verify with Firebase Auth REST API or use a JWT library
    const parts = token.split('.');
    if (parts.length !== 3) return null;

    const payload = JSON.parse(atob(parts[1].replace(/-/g, '+').replace(/_/g, '/')));

    // Check expiration
    if (payload.exp && payload.exp * 1000 < Date.now()) {
      return null;
    }

    return payload.sub || payload.user_id || null;
  } catch {
    return null;
  }
}
