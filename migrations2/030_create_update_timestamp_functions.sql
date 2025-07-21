-- Migration 030: Create update timestamp functions
-- Creates reusable functions for automatic timestamp updates
-- Single-purpose: Update timestamp functions creation only

-- Generic function to update updated_at timestamp
CREATE OR REPLACE FUNCTION unified.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to extract domain from email address
CREATE OR REPLACE FUNCTION unified.extract_domain_from_email()
RETURNS TRIGGER AS $$
BEGIN
    -- Extract domain from email address
    NEW.domain = split_part(NEW.email, '@', 2);
    
    -- Set default home directory if not provided
    IF NEW.home_directory IS NULL THEN
        NEW.home_directory = '/var/mail/' || NEW.domain || '/' || NEW.username;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update DNS zone serial number
CREATE OR REPLACE FUNCTION unified.update_dns_zone_serial()
RETURNS TRIGGER AS $$
BEGIN
    -- Update serial number and timestamp when DNS records change
    UPDATE unified.dns_zones
    SET serial_number = EXTRACT(epoch FROM CURRENT_TIMESTAMP)::bigint,
        updated_at = CURRENT_TIMESTAMP
    WHERE domain = COALESCE(NEW.domain, OLD.domain);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Comments for documentation
COMMENT ON FUNCTION unified.update_updated_at_column() IS 'Generic trigger function to update updated_at timestamp';
COMMENT ON FUNCTION unified.extract_domain_from_email() IS 'Extracts domain from email and sets default home directory for users';
COMMENT ON FUNCTION unified.update_dns_zone_serial() IS 'Updates DNS zone serial number when records are modified';