-- Migration 021: Create indexes for certificate notifications table
-- Creates performance indexes for the certificate_notifications table
-- Single-purpose: Certificate notifications table indexing only

-- Primary lookup indexes
CREATE INDEX idx_certificate_notifications_certificate_id ON unified.certificate_notifications(certificate_id);
CREATE INDEX idx_certificate_notifications_notification_type ON unified.certificate_notifications(notification_type);

-- Processing status indexes
CREATE INDEX idx_certificate_notifications_processed_at ON unified.certificate_notifications(processed_at);
CREATE INDEX idx_certificate_notifications_processed_by ON unified.certificate_notifications(processed_by);
CREATE INDEX idx_certificate_notifications_unprocessed ON unified.certificate_notifications(created_at) 
    WHERE processed_at IS NULL;

-- Error handling and retry indexes
CREATE INDEX idx_certificate_notifications_retry_count ON unified.certificate_notifications(retry_count);
CREATE INDEX idx_certificate_notifications_next_retry ON unified.certificate_notifications(next_retry_at) 
    WHERE next_retry_at IS NOT NULL;
CREATE INDEX idx_certificate_notifications_errors ON unified.certificate_notifications(error_message) 
    WHERE error_message IS NOT NULL;

-- Time-based indexes
CREATE INDEX idx_certificate_notifications_created_at ON unified.certificate_notifications(created_at);

-- Composite indexes for processing queries
CREATE INDEX idx_certificate_notifications_cert_type_created ON unified.certificate_notifications(
    certificate_id, notification_type, created_at
);
CREATE INDEX idx_certificate_notifications_unprocessed_retry ON unified.certificate_notifications(
    processed_at, next_retry_at, created_at
) WHERE processed_at IS NULL;

-- JSONB index for notification_data queries
CREATE INDEX idx_certificate_notifications_data_gin ON unified.certificate_notifications 
    USING gin(notification_data);