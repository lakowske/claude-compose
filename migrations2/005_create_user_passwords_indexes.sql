-- Migration 005: Create indexes for user passwords table
-- Creates performance indexes for the user_passwords table
-- Single-purpose: User passwords table indexing only

-- Primary lookup indexes
CREATE INDEX idx_user_passwords_user_id ON unified.user_passwords(user_id);
CREATE INDEX idx_user_passwords_service ON unified.user_passwords(service);

-- Composite index for most common query pattern
CREATE INDEX idx_user_passwords_user_service ON unified.user_passwords(user_id, service);

-- Password management indexes
CREATE INDEX idx_user_passwords_expires_at ON unified.user_passwords(expires_at) 
    WHERE expires_at IS NOT NULL;
CREATE INDEX idx_user_passwords_must_change ON unified.user_passwords(must_change_on_next_login) 
    WHERE must_change_on_next_login = true;

-- Hash scheme index for service queries
CREATE INDEX idx_user_passwords_hash_scheme ON unified.user_passwords(hash_scheme);