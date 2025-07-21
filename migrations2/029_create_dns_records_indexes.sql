-- Migration 029: Create indexes for DNS records table
-- Creates performance indexes for the dns_records table
-- Single-purpose: DNS records table indexing only

-- Primary lookup indexes
CREATE INDEX idx_dns_records_domain ON unified.dns_records(domain);
CREATE INDEX idx_dns_records_name ON unified.dns_records(name);
CREATE INDEX idx_dns_records_record_type ON unified.dns_records(record_type);

-- Status indexes
CREATE INDEX idx_dns_records_is_active ON unified.dns_records(is_active);
CREATE INDEX idx_dns_records_is_system_record ON unified.dns_records(is_system_record);

-- DNS query optimization indexes
CREATE INDEX idx_dns_records_domain_name ON unified.dns_records(domain, name);
CREATE INDEX idx_dns_records_domain_name_type ON unified.dns_records(domain, name, record_type);
CREATE INDEX idx_dns_records_domain_type ON unified.dns_records(domain, record_type);

-- Record type specific indexes
CREATE INDEX idx_dns_records_mx_priority ON unified.dns_records(domain, priority) 
    WHERE record_type = 'MX';
CREATE INDEX idx_dns_records_srv_priority_weight ON unified.dns_records(domain, priority, weight, port) 
    WHERE record_type = 'SRV';
CREATE INDEX idx_dns_records_ns_records ON unified.dns_records(domain, value) 
    WHERE record_type = 'NS';

-- Active records indexes for performance
CREATE INDEX idx_dns_records_domain_active ON unified.dns_records(domain, is_active);
CREATE INDEX idx_dns_records_name_active ON unified.dns_records(name, is_active);
CREATE INDEX idx_dns_records_type_active ON unified.dns_records(record_type, is_active);

-- Full DNS resolution index
CREATE INDEX idx_dns_records_resolution ON unified.dns_records(domain, name, record_type, is_active);

-- Value-based searches (for reverse lookups)
CREATE INDEX idx_dns_records_value ON unified.dns_records(value);
CREATE INDEX idx_dns_records_value_hash ON unified.dns_records(
    md5(value)
) WHERE length(value) > 100; -- For long TXT records

-- TTL-based queries
CREATE INDEX idx_dns_records_ttl ON unified.dns_records(ttl);

-- Time-based indexes
CREATE INDEX idx_dns_records_created_at ON unified.dns_records(created_at);
CREATE INDEX idx_dns_records_updated_at ON unified.dns_records(updated_at);