-- Migration 015: Create indexes for mailbox events table
-- Creates performance indexes for the mailbox_events table
-- Single-purpose: Mailbox events table indexing only

-- Primary lookup indexes
CREATE INDEX idx_mailbox_events_user_id ON unified.mailbox_events(user_id);
CREATE INDEX idx_mailbox_events_event_type ON unified.mailbox_events(event_type);
CREATE INDEX idx_mailbox_events_username ON unified.mailbox_events(username);
CREATE INDEX idx_mailbox_events_domain ON unified.mailbox_events(domain);

-- Processing status indexes
CREATE INDEX idx_mailbox_events_processed ON unified.mailbox_events(processed);
CREATE INDEX idx_mailbox_events_processed_false ON unified.mailbox_events(processed, created_at) 
    WHERE processed = false;
CREATE INDEX idx_mailbox_events_processed_by ON unified.mailbox_events(processed_by);

-- Error handling and retry indexes
CREATE INDEX idx_mailbox_events_retry_count ON unified.mailbox_events(retry_count);
CREATE INDEX idx_mailbox_events_next_retry ON unified.mailbox_events(next_retry_at) 
    WHERE next_retry_at IS NOT NULL;
CREATE INDEX idx_mailbox_events_errors ON unified.mailbox_events(error_message) 
    WHERE error_message IS NOT NULL;

-- Time-based indexes
CREATE INDEX idx_mailbox_events_created_at ON unified.mailbox_events(created_at);
CREATE INDEX idx_mailbox_events_processed_at ON unified.mailbox_events(processed_at);

-- Composite indexes for processing queries
CREATE INDEX idx_mailbox_events_unprocessed_retry ON unified.mailbox_events(
    processed, next_retry_at, created_at
) WHERE processed = false;

-- JSONB index for event_data queries
CREATE INDEX idx_mailbox_events_event_data_gin ON unified.mailbox_events USING gin(event_data);