-- Migration 012: Create audit log table
-- Creates comprehensive audit logging table
-- Single-purpose: Audit log table creation only

CREATE TABLE unified.audit_log (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    session_id VARCHAR(255),
    service VARCHAR(50),
    action VARCHAR(100) NOT NULL,
    resource VARCHAR(500),
    resource_id INTEGER,
    
    -- Request context
    ip_address INET,
    user_agent TEXT,
    request_method VARCHAR(10),
    request_path VARCHAR(1000),
    
    -- Result
    success BOOLEAN NOT NULL,
    status_code INTEGER,
    error_message TEXT,
    
    -- Additional structured data
    additional_data JSONB,
    
    -- Performance tracking
    duration_ms INTEGER,
    
    -- Timestamp
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT audit_log_action_not_empty CHECK (length(trim(action)) > 0),
    CONSTRAINT audit_log_service_valid CHECK (
        service IS NULL OR service IN ('apache', 'dovecot', 'webdav', 'samba', 'api', 'web', 'admin')
    ),
    CONSTRAINT audit_log_request_method_valid CHECK (
        request_method IS NULL OR request_method IN ('GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS')
    ),
    CONSTRAINT audit_log_status_code_valid CHECK (
        status_code IS NULL OR (status_code >= 100 AND status_code <= 599)
    ),
    CONSTRAINT audit_log_duration_positive CHECK (duration_ms IS NULL OR duration_ms >= 0)
);

-- Add foreign key constraint (allow NULL for system actions)
ALTER TABLE unified.audit_log 
    ADD CONSTRAINT fk_audit_log_user_id 
    FOREIGN KEY (user_id) REFERENCES unified.users(id) ON DELETE SET NULL;

-- Comments for documentation
COMMENT ON TABLE unified.audit_log IS 'Comprehensive audit log for all system actions and events';
COMMENT ON COLUMN unified.audit_log.action IS 'Action performed (login, logout, create_user, update_password, etc.)';
COMMENT ON COLUMN unified.audit_log.resource IS 'Resource affected by the action (table name, endpoint, file path)';
COMMENT ON COLUMN unified.audit_log.resource_id IS 'ID of the specific resource affected';
COMMENT ON COLUMN unified.audit_log.session_id IS 'Session identifier for tracking user sessions';
COMMENT ON COLUMN unified.audit_log.additional_data IS 'Additional structured data specific to the action';
COMMENT ON COLUMN unified.audit_log.duration_ms IS 'Time taken to complete the action in milliseconds';