-- Migration 004: Create user passwords table
-- Creates service-compatible password storage table
-- Single-purpose: User passwords table creation only

CREATE TABLE unified.user_passwords (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    service VARCHAR(50) NOT NULL,
    
    -- Password in format expected by service
    password_hash TEXT NOT NULL,
    hash_scheme VARCHAR(50) NOT NULL,
    
    -- Password policy tracking
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,
    must_change_on_next_login BOOLEAN DEFAULT false,
    
    -- Constraints
    CONSTRAINT user_passwords_user_service_unique UNIQUE(user_id, service),
    CONSTRAINT user_passwords_hash_scheme_valid CHECK (
        hash_scheme IN ('PLAIN', 'CRYPT', 'SHA256', 'SSHA', 'BCRYPT', 'PBKDF2', 'ARGON2')
    ),
    CONSTRAINT user_passwords_service_valid CHECK (
        service IN ('apache', 'dovecot', 'webdav', 'samba', 'api')
    )
);

-- Add foreign key constraint
ALTER TABLE unified.user_passwords 
    ADD CONSTRAINT fk_user_passwords_user_id 
    FOREIGN KEY (user_id) REFERENCES unified.users(id) ON DELETE CASCADE;

-- Comments for documentation
COMMENT ON TABLE unified.user_passwords IS 'Service-specific password storage with multiple hash format support';
COMMENT ON COLUMN unified.user_passwords.service IS 'Service name (apache, dovecot, webdav, samba, api)';
COMMENT ON COLUMN unified.user_passwords.hash_scheme IS 'Password hash scheme used by the service';
COMMENT ON COLUMN unified.user_passwords.expires_at IS 'Password expiration timestamp (NULL for no expiration)';