-- Migration 003: Create indexes for users table
-- Creates performance indexes for the users table
-- Single-purpose: Users table indexing only

-- Core user lookup indexes
CREATE INDEX idx_users_email ON unified.users(email);
CREATE INDEX idx_users_username ON unified.users(username);
CREATE INDEX idx_users_domain ON unified.users(domain);
CREATE INDEX idx_users_is_active ON unified.users(is_active);
CREATE INDEX idx_users_email_verified ON unified.users(email_verified);

-- Security-related indexes
CREATE INDEX idx_users_is_locked ON unified.users(is_locked);
CREATE INDEX idx_users_failed_login_attempts ON unified.users(failed_login_attempts);

-- Token-related indexes for performance
CREATE INDEX idx_users_email_verification_token ON unified.users(email_verification_token) 
    WHERE email_verification_token IS NOT NULL;
CREATE INDEX idx_users_password_reset_token ON unified.users(password_reset_token) 
    WHERE password_reset_token IS NOT NULL;

-- Timestamp indexes for reporting and cleanup
CREATE INDEX idx_users_created_at ON unified.users(created_at);
CREATE INDEX idx_users_last_login_at ON unified.users(last_login_at);

-- Composite indexes for common queries
CREATE INDEX idx_users_domain_active ON unified.users(domain, is_active);
CREATE INDEX idx_users_email_active_verified ON unified.users(email, is_active, email_verified);