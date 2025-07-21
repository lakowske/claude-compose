-- Migration 011: Create indexes for email aliases table
-- Creates performance indexes for the email_aliases table
-- Single-purpose: Email aliases table indexing only

-- Primary lookup indexes
CREATE INDEX idx_email_aliases_user_id ON unified.email_aliases(user_id);
CREATE INDEX idx_email_aliases_alias_email ON unified.email_aliases(alias_email);
CREATE INDEX idx_email_aliases_destination_email ON unified.email_aliases(destination_email);

-- Status indexes
CREATE INDEX idx_email_aliases_is_active ON unified.email_aliases(is_active);
CREATE INDEX idx_email_aliases_is_primary ON unified.email_aliases(is_primary) 
    WHERE is_primary = true;
CREATE INDEX idx_email_aliases_is_catch_all ON unified.email_aliases(is_catch_all) 
    WHERE is_catch_all = true;

-- Composite indexes for common query patterns
CREATE INDEX idx_email_aliases_user_active ON unified.email_aliases(user_id, is_active);
CREATE INDEX idx_email_aliases_alias_active ON unified.email_aliases(alias_email, is_active);

-- Domain-based indexes for mail routing
CREATE INDEX idx_email_aliases_alias_domain ON unified.email_aliases(
    split_part(alias_email, '@', 2)
);
CREATE INDEX idx_email_aliases_destination_domain ON unified.email_aliases(
    split_part(destination_email, '@', 2)
);

-- Timestamp indexes
CREATE INDEX idx_email_aliases_created_at ON unified.email_aliases(created_at);
CREATE INDEX idx_email_aliases_updated_at ON unified.email_aliases(updated_at);