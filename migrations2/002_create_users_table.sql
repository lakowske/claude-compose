-- Migration 002: Create users table
-- Creates the main users table with consistent naming and timezone-aware timestamps
-- Single-purpose: Users table creation only

CREATE TABLE unified.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    domain VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    
    -- System mapping for dovecot
    system_uid INTEGER DEFAULT 5000,
    system_gid INTEGER DEFAULT 5000,
    home_directory VARCHAR(500),
    mailbox_format VARCHAR(20) DEFAULT 'maildir',
    
    -- Account status
    is_active BOOLEAN DEFAULT true,
    is_locked BOOLEAN DEFAULT false,
    email_verified BOOLEAN DEFAULT false,
    
    -- Email verification
    email_verification_token VARCHAR(255),
    email_verification_expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Password reset
    password_reset_token VARCHAR(255),
    password_reset_expires_at TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps - all timezone-aware
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP WITH TIME ZONE,
    
    -- Security tracking
    failed_login_attempts INTEGER DEFAULT 0,
    last_failed_login_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT users_domain_matches_email CHECK (email LIKE '%@' || domain),
    CONSTRAINT users_mailbox_format_valid CHECK (mailbox_format IN ('maildir', 'mbox')),
    CONSTRAINT users_system_uid_positive CHECK (system_uid > 0),
    CONSTRAINT users_system_gid_positive CHECK (system_gid > 0)
);

-- Comments for documentation
COMMENT ON TABLE unified.users IS 'Main users table with service compatibility for Apache, Dovecot, and other services';
COMMENT ON COLUMN unified.users.domain IS 'Email domain extracted from email address for dovecot compatibility';
COMMENT ON COLUMN unified.users.system_uid IS 'System UID for mail service (default vmail user)';
COMMENT ON COLUMN unified.users.system_gid IS 'System GID for mail service (default vmail group)';
COMMENT ON COLUMN unified.users.home_directory IS 'Mail home directory path for dovecot';
COMMENT ON COLUMN unified.users.mailbox_format IS 'Mail storage format (maildir or mbox)';