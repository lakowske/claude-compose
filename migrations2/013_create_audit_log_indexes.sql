-- Migration 013: Create indexes for audit log table
-- Creates performance indexes for the audit_log table
-- Single-purpose: Audit log table indexing only

-- Primary lookup indexes
CREATE INDEX idx_audit_log_user_id ON unified.audit_log(user_id);
CREATE INDEX idx_audit_log_session_id ON unified.audit_log(session_id);
CREATE INDEX idx_audit_log_service ON unified.audit_log(service);
CREATE INDEX idx_audit_log_action ON unified.audit_log(action);

-- Resource tracking indexes
CREATE INDEX idx_audit_log_resource ON unified.audit_log(resource);
CREATE INDEX idx_audit_log_resource_id ON unified.audit_log(resource_id);
CREATE INDEX idx_audit_log_resource_resource_id ON unified.audit_log(resource, resource_id);

-- Security and monitoring indexes
CREATE INDEX idx_audit_log_ip_address ON unified.audit_log(ip_address);
CREATE INDEX idx_audit_log_success ON unified.audit_log(success);
CREATE INDEX idx_audit_log_success_false ON unified.audit_log(success) WHERE success = false;

-- Time-based indexes for queries and cleanup
CREATE INDEX idx_audit_log_created_at ON unified.audit_log(created_at);
CREATE INDEX idx_audit_log_created_at_desc ON unified.audit_log(created_at DESC);

-- Composite indexes for common query patterns
CREATE INDEX idx_audit_log_user_created ON unified.audit_log(user_id, created_at);
CREATE INDEX idx_audit_log_service_created ON unified.audit_log(service, created_at);
CREATE INDEX idx_audit_log_action_created ON unified.audit_log(action, created_at);
CREATE INDEX idx_audit_log_ip_created ON unified.audit_log(ip_address, created_at);

-- Performance monitoring indexes
CREATE INDEX idx_audit_log_duration_ms ON unified.audit_log(duration_ms) 
    WHERE duration_ms IS NOT NULL;

-- JSONB indexes for additional_data queries
CREATE INDEX idx_audit_log_additional_data_gin ON unified.audit_log USING gin(additional_data);

-- Partial index for errors only
CREATE INDEX idx_audit_log_errors ON unified.audit_log(user_id, action, created_at) 
    WHERE success = false;