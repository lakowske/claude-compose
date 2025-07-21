-- Migration 006: Create user roles table
-- Creates simplified roles table for service compatibility
-- Single-purpose: User roles table creation only

CREATE TABLE unified.user_roles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    role_name VARCHAR(50) NOT NULL,
    service VARCHAR(50) NOT NULL,
    granted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    granted_by INTEGER,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    
    -- Constraints
    CONSTRAINT user_roles_user_service_role_unique UNIQUE(user_id, service, role_name),
    CONSTRAINT user_roles_role_name_valid CHECK (
        role_name IN ('admin', 'user', 'customer', 'moderator', 'no_email', 'readonly')
    ),
    CONSTRAINT user_roles_service_valid CHECK (
        service IN ('apache', 'dovecot', 'webdav', 'samba', 'api', 'global')
    )
);

-- Add foreign key constraints
ALTER TABLE unified.user_roles 
    ADD CONSTRAINT fk_user_roles_user_id 
    FOREIGN KEY (user_id) REFERENCES unified.users(id) ON DELETE CASCADE;

ALTER TABLE unified.user_roles 
    ADD CONSTRAINT fk_user_roles_granted_by 
    FOREIGN KEY (granted_by) REFERENCES unified.users(id) ON DELETE SET NULL;

-- Comments for documentation
COMMENT ON TABLE unified.user_roles IS 'Service-specific user roles and permissions';
COMMENT ON COLUMN unified.user_roles.role_name IS 'Role name (admin, user, customer, moderator, no_email, readonly)';
COMMENT ON COLUMN unified.user_roles.service IS 'Service scope for the role (apache, dovecot, webdav, samba, api, global)';
COMMENT ON COLUMN unified.user_roles.granted_by IS 'User ID who granted this role (NULL for system-granted)';
COMMENT ON COLUMN unified.user_roles.expires_at IS 'Role expiration timestamp (NULL for permanent)';