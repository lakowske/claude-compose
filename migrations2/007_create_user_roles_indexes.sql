-- Migration 007: Create indexes for user roles table
-- Creates performance indexes for the user_roles table
-- Single-purpose: User roles table indexing only

-- Primary lookup indexes
CREATE INDEX idx_user_roles_user_id ON unified.user_roles(user_id);
CREATE INDEX idx_user_roles_service ON unified.user_roles(service);
CREATE INDEX idx_user_roles_role_name ON unified.user_roles(role_name);

-- Composite indexes for common query patterns
CREATE INDEX idx_user_roles_user_service ON unified.user_roles(user_id, service);
CREATE INDEX idx_user_roles_user_service_active ON unified.user_roles(user_id, service, is_active);
CREATE INDEX idx_user_roles_service_role ON unified.user_roles(service, role_name);

-- Management indexes
CREATE INDEX idx_user_roles_granted_by ON unified.user_roles(granted_by) 
    WHERE granted_by IS NOT NULL;
CREATE INDEX idx_user_roles_is_active ON unified.user_roles(is_active);
CREATE INDEX idx_user_roles_expires_at ON unified.user_roles(expires_at) 
    WHERE expires_at IS NOT NULL;

-- Timestamp indexes for auditing
CREATE INDEX idx_user_roles_granted_at ON unified.user_roles(granted_at);