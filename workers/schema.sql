-- 유저 프로필 (CRM 기본)
CREATE TABLE IF NOT EXISTS user_profiles (
  firebase_uid TEXT PRIMARY KEY,
  fcm_token TEXT,
  device_os TEXT,
  segments TEXT DEFAULT 'free',
  utm_source TEXT,
  utm_medium TEXT,
  last_online_at INTEGER,
  created_at INTEGER DEFAULT (unixepoch())
);

-- 푸시 발송 이력
CREATE TABLE IF NOT EXISTS push_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  target_segment TEXT,
  title TEXT,
  body TEXT,
  sent_count INTEGER,
  sent_at INTEGER DEFAULT (unixepoch())
);

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_user_segments ON user_profiles(segments);
CREATE INDEX IF NOT EXISTS idx_user_last_online ON user_profiles(last_online_at);
