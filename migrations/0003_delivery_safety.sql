ALTER TABLE users ADD COLUMN topic_card_message_id INTEGER;

-- Existing topics already received their identity card before this column existed.
UPDATE users SET topic_card_message_id = 0 WHERE topic_id IS NOT NULL;
