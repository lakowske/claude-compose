-- Migration 009: Create indexes for user quotas table
-- Creates performance indexes for the user_quotas table
-- Single-purpose: User quotas table indexing only

-- Primary lookup indexes
CREATE INDEX idx_user_quotas_user_id ON unified.user_quotas(user_id);
CREATE INDEX idx_user_quotas_service ON unified.user_quotas(service);
CREATE INDEX idx_user_quotas_quota_type ON unified.user_quotas(quota_type);

-- Composite indexes for common query patterns
CREATE INDEX idx_user_quotas_user_service ON unified.user_quotas(user_id, service);
CREATE INDEX idx_user_quotas_user_service_type ON unified.user_quotas(user_id, service, quota_type);
CREATE INDEX idx_user_quotas_service_type ON unified.user_quotas(service, quota_type);

-- Usage monitoring indexes
CREATE INDEX idx_user_quotas_current_usage ON unified.user_quotas(current_usage);
CREATE INDEX idx_user_quotas_usage_ratio ON unified.user_quotas(
    CASE WHEN quota_value > 0 THEN (current_usage::float / quota_value) ELSE 0 END
) WHERE quota_value IS NOT NULL AND quota_value > 0;

-- Timestamp indexes for auditing
CREATE INDEX idx_user_quotas_updated_at ON unified.user_quotas(updated_at);