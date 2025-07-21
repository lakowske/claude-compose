-- Migration 010: Create email aliases table
-- Creates email aliases table for mail services
-- Single-purpose: Email aliases table creation only

CREATE TABLE unified.email_aliases (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    alias_email VARCHAR(255) NOT NULL UNIQUE,
    destination_email VARCHAR(255) NOT NULL,
    is_primary BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    is_catch_all BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT email_aliases_alias_email_format CHECK (alias_email ~ '^[^@]+@[^@]+\.[^@]+$'),
    CONSTRAINT email_aliases_destination_email_format CHECK (destination_email ~ '^[^@]+@[^@]+\.[^@]+$'),
    CONSTRAINT email_aliases_not_self_reference CHECK (alias_email != destination_email)
);

-- Add foreign key constraint
ALTER TABLE unified.email_aliases 
    ADD CONSTRAINT fk_email_aliases_user_id 
    FOREIGN KEY (user_id) REFERENCES unified.users(id) ON DELETE CASCADE;

-- Ensure only one primary alias per user
CREATE UNIQUE INDEX idx_email_aliases_user_primary 
    ON unified.email_aliases(user_id) 
    WHERE is_primary = true;

-- Comments for documentation
COMMENT ON TABLE unified.email_aliases IS 'Email aliases and forwarding configuration for mail services';
COMMENT ON COLUMN unified.email_aliases.alias_email IS 'The alias email address (what mail is sent to)';
COMMENT ON COLUMN unified.email_aliases.destination_email IS 'The destination email address (where mail is forwarded)';
COMMENT ON COLUMN unified.email_aliases.is_primary IS 'Whether this is the primary email alias for the user';
COMMENT ON COLUMN unified.email_aliases.is_catch_all IS 'Whether this alias catches all mail for the domain';