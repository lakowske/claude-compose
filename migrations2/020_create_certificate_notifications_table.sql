-- Migration 020: Create certificate notifications table
-- Creates table for certificate change notifications
-- Single-purpose: Certificate notifications table creation only

CREATE TABLE unified.certificate_notifications (
    id SERIAL PRIMARY KEY,
    certificate_id INTEGER NOT NULL,
    
    -- Notification details
    notification_type VARCHAR(50) NOT NULL,
    message TEXT,
    notification_data JSONB,
    
    -- Processing status
    processed_at TIMESTAMP WITH TIME ZONE,
    processed_by VARCHAR(100),
    
    -- Error handling
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    next_retry_at TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT certificate_notifications_type_valid CHECK (
        notification_type IN ('created', 'updated', 'renewed', 'expired', 'error', 'deleted', 'warning')
    ),
    CONSTRAINT certificate_notifications_retry_count_positive CHECK (retry_count >= 0)
);

-- Add foreign key constraint
ALTER TABLE unified.certificate_notifications 
    ADD CONSTRAINT fk_certificate_notifications_certificate_id 
    FOREIGN KEY (certificate_id) REFERENCES unified.certificates(id) ON DELETE CASCADE;

-- Comments for documentation
COMMENT ON TABLE unified.certificate_notifications IS 'Certificate change notifications for LISTEN/NOTIFY system';
COMMENT ON COLUMN unified.certificate_notifications.notification_type IS 'Type of notification (created, updated, renewed, expired, error, deleted, warning)';
COMMENT ON COLUMN unified.certificate_notifications.notification_data IS 'Additional structured data for the notification';
COMMENT ON COLUMN unified.certificate_notifications.processed_by IS 'Service or process that handled the notification';
COMMENT ON COLUMN unified.certificate_notifications.retry_count IS 'Number of times notification processing has been retried';