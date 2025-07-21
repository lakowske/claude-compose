-- Migration 014: Create mailbox events table
-- Creates mailbox events table for LISTEN/NOTIFY system
-- Single-purpose: Mailbox events table creation only

CREATE TABLE unified.mailbox_events (
    id SERIAL PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    user_id INTEGER,
    username VARCHAR(255),
    email VARCHAR(255),
    domain VARCHAR(255),
    home_directory VARCHAR(500),
    
    -- Event data and processing
    event_data JSONB,
    processed BOOLEAN DEFAULT false,
    processed_at TIMESTAMP WITH TIME ZONE,
    processed_by VARCHAR(100),
    
    -- Error handling
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    next_retry_at TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT mailbox_events_event_type_valid CHECK (
        event_type IN ('created', 'updated', 'deleted', 'quota_exceeded', 'quota_warning')
    ),
    CONSTRAINT mailbox_events_retry_count_positive CHECK (retry_count >= 0),
    CONSTRAINT mailbox_events_email_format CHECK (
        email IS NULL OR email ~ '^[^@]+@[^@]+\.[^@]+$'
    )
);

-- Add foreign key constraint (allow NULL for deleted users)
ALTER TABLE unified.mailbox_events 
    ADD CONSTRAINT fk_mailbox_events_user_id 
    FOREIGN KEY (user_id) REFERENCES unified.users(id) ON DELETE SET NULL;

-- Comments for documentation
COMMENT ON TABLE unified.mailbox_events IS 'Events for mailbox creation, updates, and deletion via LISTEN/NOTIFY';
COMMENT ON COLUMN unified.mailbox_events.event_type IS 'Type of mailbox event (created, updated, deleted, quota_exceeded, quota_warning)';
COMMENT ON COLUMN unified.mailbox_events.event_data IS 'Additional structured data for the event';
COMMENT ON COLUMN unified.mailbox_events.processed_by IS 'Service or process that handled the event';
COMMENT ON COLUMN unified.mailbox_events.retry_count IS 'Number of times processing has been retried';
COMMENT ON COLUMN unified.mailbox_events.next_retry_at IS 'When to retry processing this event';