-- Migration 026: Create DNS zones table
-- Creates DNS zone metadata management table
-- Single-purpose: DNS zones table creation only

CREATE TABLE unified.dns_zones (
    id SERIAL PRIMARY KEY,
    domain VARCHAR(255) NOT NULL UNIQUE,
    
    -- SOA record fields
    serial_number BIGINT NOT NULL,
    refresh_interval INTEGER NOT NULL DEFAULT 3600,
    retry_interval INTEGER NOT NULL DEFAULT 1800,
    expire_interval INTEGER NOT NULL DEFAULT 604800,
    minimum_ttl INTEGER NOT NULL DEFAULT 3600,
    primary_ns VARCHAR(255) NOT NULL,
    admin_email VARCHAR(255) NOT NULL,
    
    -- Zone management
    is_active BOOLEAN DEFAULT true,
    zone_type VARCHAR(20) DEFAULT 'master',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT dns_zones_domain_format CHECK (
        domain ~ '^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$'
    ),
    CONSTRAINT dns_zones_refresh_interval_positive CHECK (refresh_interval > 0),
    CONSTRAINT dns_zones_retry_interval_positive CHECK (retry_interval > 0),
    CONSTRAINT dns_zones_expire_interval_positive CHECK (expire_interval > 0),
    CONSTRAINT dns_zones_minimum_ttl_positive CHECK (minimum_ttl > 0),
    CONSTRAINT dns_zones_serial_number_positive CHECK (serial_number > 0),
    CONSTRAINT dns_zones_zone_type_valid CHECK (
        zone_type IN ('master', 'slave', 'stub', 'forward')
    ),
    CONSTRAINT dns_zones_admin_email_format CHECK (
        admin_email ~ '^[^@]+@[^@]+\.[^@]+$'
    )
);

-- Comments for documentation
COMMENT ON TABLE unified.dns_zones IS 'DNS zone metadata and SOA record management';
COMMENT ON COLUMN unified.dns_zones.serial_number IS 'DNS zone serial number for change tracking';
COMMENT ON COLUMN unified.dns_zones.primary_ns IS 'Primary nameserver for the zone';
COMMENT ON COLUMN unified.dns_zones.admin_email IS 'Administrative contact email for the zone';
COMMENT ON COLUMN unified.dns_zones.zone_type IS 'DNS zone type (master, slave, stub, forward)';
COMMENT ON COLUMN unified.dns_zones.refresh_interval IS 'How often secondary servers check for updates (seconds)';
COMMENT ON COLUMN unified.dns_zones.retry_interval IS 'How often to retry failed zone transfers (seconds)';
COMMENT ON COLUMN unified.dns_zones.expire_interval IS 'When to stop answering queries if primary is unreachable (seconds)';
COMMENT ON COLUMN unified.dns_zones.minimum_ttl IS 'Minimum TTL for negative caching (seconds)';