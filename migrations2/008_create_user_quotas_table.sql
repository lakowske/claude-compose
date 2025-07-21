-- Migration 008: Create user quotas table
-- Creates service quotas and limits table
-- Single-purpose: User quotas table creation only

CREATE TABLE unified.user_quotas (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    service VARCHAR(50) NOT NULL,
    quota_type VARCHAR(50) NOT NULL,
    quota_value BIGINT,
    quota_unit VARCHAR(20),
    current_usage BIGINT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT user_quotas_user_service_type_unique UNIQUE(user_id, service, quota_type),
    CONSTRAINT user_quotas_quota_type_valid CHECK (
        quota_type IN ('storage', 'bandwidth', 'connections', 'files', 'messages')
    ),
    CONSTRAINT user_quotas_service_valid CHECK (
        service IN ('dovecot', 'apache', 'webdav', 'samba', 'api')
    ),
    CONSTRAINT user_quotas_quota_unit_valid CHECK (
        quota_unit IN ('bytes', 'KB', 'MB', 'GB', 'TB', 'count', 'per_hour', 'per_day')
    ),
    CONSTRAINT user_quotas_quota_value_positive CHECK (quota_value IS NULL OR quota_value >= 0),
    CONSTRAINT user_quotas_current_usage_positive CHECK (current_usage >= 0)
);

-- Add foreign key constraint
ALTER TABLE unified.user_quotas 
    ADD CONSTRAINT fk_user_quotas_user_id 
    FOREIGN KEY (user_id) REFERENCES unified.users(id) ON DELETE CASCADE;

-- Comments for documentation
COMMENT ON TABLE unified.user_quotas IS 'Service-specific quotas and resource limits per user';
COMMENT ON COLUMN unified.user_quotas.quota_type IS 'Type of quota (storage, bandwidth, connections, files, messages)';
COMMENT ON COLUMN unified.user_quotas.quota_value IS 'Maximum allowed value (NULL for unlimited)';
COMMENT ON COLUMN unified.user_quotas.quota_unit IS 'Unit of measurement for quota_value and current_usage';
COMMENT ON COLUMN unified.user_quotas.current_usage IS 'Current usage amount in quota_unit';