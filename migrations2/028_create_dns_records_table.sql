-- Migration 028: Create DNS records table
-- Creates DNS records management table
-- Single-purpose: DNS records table creation only

CREATE TABLE unified.dns_records (
    id SERIAL PRIMARY KEY,
    domain VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    record_type VARCHAR(10) NOT NULL,
    value TEXT NOT NULL,
    ttl INTEGER NOT NULL DEFAULT 3600,
    priority INTEGER,
    weight INTEGER,
    port INTEGER,
    
    -- Record management
    is_active BOOLEAN DEFAULT true,
    is_system_record BOOLEAN DEFAULT false,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT dns_records_domain_name_type_unique UNIQUE(domain, name, record_type),
    CONSTRAINT dns_records_domain_format CHECK (
        domain ~ '^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?)*$'
    ),
    CONSTRAINT dns_records_record_type_valid CHECK (
        record_type IN ('A', 'AAAA', 'CNAME', 'MX', 'TXT', 'SRV', 'NS', 'PTR', 'SOA', 'CAA', 'DKIM', 'SPF')
    ),
    CONSTRAINT dns_records_ttl_positive CHECK (ttl > 0),
    CONSTRAINT dns_records_priority_positive CHECK (priority IS NULL OR priority >= 0),
    CONSTRAINT dns_records_weight_positive CHECK (weight IS NULL OR weight >= 0),
    CONSTRAINT dns_records_port_valid CHECK (port IS NULL OR (port > 0 AND port <= 65535)),
    CONSTRAINT dns_records_value_not_empty CHECK (length(trim(value)) > 0),
    -- MX and SRV records require priority
    CONSTRAINT dns_records_mx_priority CHECK (
        record_type != 'MX' OR priority IS NOT NULL
    ),
    CONSTRAINT dns_records_srv_priority_weight_port CHECK (
        record_type != 'SRV' OR (priority IS NOT NULL AND weight IS NOT NULL AND port IS NOT NULL)
    )
);

-- Comments for documentation
COMMENT ON TABLE unified.dns_records IS 'DNS records for domain management';
COMMENT ON COLUMN unified.dns_records.name IS 'Record name (@ for zone apex, subdomain names, or FQDN)';
COMMENT ON COLUMN unified.dns_records.record_type IS 'DNS record type (A, AAAA, CNAME, MX, TXT, SRV, NS, PTR, SOA, CAA, DKIM, SPF)';
COMMENT ON COLUMN unified.dns_records.value IS 'Record value (IP address, hostname, text content)';
COMMENT ON COLUMN unified.dns_records.ttl IS 'Time to live in seconds';
COMMENT ON COLUMN unified.dns_records.priority IS 'Record priority (required for MX and SRV records)';
COMMENT ON COLUMN unified.dns_records.weight IS 'Record weight (used by SRV records)';
COMMENT ON COLUMN unified.dns_records.port IS 'Port number (used by SRV records)';
COMMENT ON COLUMN unified.dns_records.is_system_record IS 'Whether this is a system-managed record (not user-editable)';