ALTER TABLE users ADD COLUMN topic_lease_until INTEGER NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN last_rate_key TEXT;
ALTER TABLE users ADD COLUMN blocked_notice_at INTEGER NOT NULL DEFAULT 0;

ALTER TABLE processed_updates ADD COLUMN status TEXT NOT NULL DEFAULT 'done';
ALTER TABLE processed_updates ADD COLUMN attempts INTEGER NOT NULL DEFAULT 1;
ALTER TABLE processed_updates ADD COLUMN last_error TEXT;
ALTER TABLE processed_updates ADD COLUMN updated_at INTEGER;

UPDATE processed_updates SET updated_at = processed_at WHERE updated_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_processed_updates_status
  ON processed_updates(status, updated_at);

CREATE TABLE IF NOT EXISTS media_groups (
  source_chat_id TEXT NOT NULL,
  media_group_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  direction TEXT NOT NULL CHECK (direction IN ('user_to_admin', 'admin_to_user')),
  state TEXT NOT NULL CHECK (state IN ('initializing', 'collecting', 'processing', 'done', 'rejected')),
  updated_at_ms INTEGER NOT NULL,
  lease_until_ms INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  last_error TEXT,
  PRIMARY KEY (source_chat_id, media_group_id)
);

CREATE INDEX IF NOT EXISTS idx_media_groups_state
  ON media_groups(state, updated_at_ms);

CREATE TABLE IF NOT EXISTS media_group_messages (
  source_chat_id TEXT NOT NULL,
  media_group_id TEXT NOT NULL,
  message_id INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  PRIMARY KEY (source_chat_id, media_group_id, message_id)
);

CREATE INDEX IF NOT EXISTS idx_media_group_messages_created
  ON media_group_messages(created_at);
