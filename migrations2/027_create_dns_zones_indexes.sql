-- Migration 027: Create indexes for DNS zones table
-- Creates performance indexes for the dns_zones table
-- Single-purpose: DNS zones table indexing only

-- Primary lookup indexes
CREATE INDEX idx_dns_zones_domain ON unified.dns_zones(domain);
CREATE INDEX idx_dns_zones_primary_ns ON unified.dns_zones(primary_ns);
CREATE INDEX idx_dns_zones_admin_email ON unified.dns_zones(admin_email);

-- Status and type indexes
CREATE INDEX idx_dns_zones_is_active ON unified.dns_zones(is_active);
CREATE INDEX idx_dns_zones_zone_type ON unified.dns_zones(zone_type);
CREATE INDEX idx_dns_zones_active_type ON unified.dns_zones(is_active, zone_type);

-- SOA record indexes
CREATE INDEX idx_dns_zones_serial_number ON unified.dns_zones(serial_number);

-- Time-based indexes for monitoring
CREATE INDEX idx_dns_zones_updated_at ON unified.dns_zones(updated_at);
CREATE INDEX idx_dns_zones_created_at ON unified.dns_zones(created_at);

-- Domain hierarchy lookup (for subdomain queries)
CREATE INDEX idx_dns_zones_domain_hierarchy ON unified.dns_zones(reverse(domain));

-- Composite indexes for common queries
CREATE INDEX idx_dns_zones_domain_active ON unified.dns_zones(domain, is_active);