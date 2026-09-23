CREATE TABLE IF NOT EXISTS users (
  user_id TEXT PRIMARY KEY,
  username TEXT,
  first_name TEXT NOT NULL DEFAULT '',
  last_name TEXT NOT NULL DEFAULT '',
  topic_id INTEGER UNIQUE,
  blocked INTEGER NOT NULL DEFAULT 0 CHECK (blocked IN (0, 1)),
  last_message_at INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS message_map (
  source_chat_id TEXT NOT NULL,
  source_message_id INTEGER NOT NULL,
  target_chat_id TEXT NOT NULL,
  target_message_id INTEGER NOT NULL,
  user_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  PRIMARY KEY (source_chat_id, source_message_id)
);

CREATE INDEX IF NOT EXISTS idx_message_map_target
  ON message_map(target_chat_id, target_message_id);
CREATE INDEX IF NOT EXISTS idx_message_map_created
  ON message_map(created_at);

CREATE TABLE IF NOT EXISTS processed_updates (
  update_id INTEGER PRIMARY KEY,
  processed_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_processed_updates_time
  ON processed_updates(processed_at);
