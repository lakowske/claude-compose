-- Migration 024: Create service certificates table
-- Creates service certificate usage tracking table
-- Single-purpose: Service certificates table creation only

CREATE TABLE unified.service_certificates (
    id SERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    domain VARCHAR(255) NOT NULL,
    certificate_type VARCHAR(50) NOT NULL,
    
    -- SSL configuration
    ssl_enabled BOOLEAN DEFAULT false,
    certificate_path VARCHAR(500),
    private_key_path VARCHAR(500),
    chain_path VARCHAR(500),
    
    -- Status and tracking
    is_active BOOLEAN DEFAULT true,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_reload TIMESTAMP WITH TIME ZONE,
    
    -- Configuration details
    ssl_protocols TEXT[],
    ssl_ciphers TEXT,
    hsts_enabled BOOLEAN DEFAULT false,
    hsts_max_age INTEGER DEFAULT 31536000,
    
    -- Health check
    last_health_check TIMESTAMP WITH TIME ZONE,
    health_status VARCHAR(20) DEFAULT 'unknown',
    health_error TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT service_certificates_service_domain_unique UNIQUE(service_name, domain),
    CONSTRAINT service_certificates_certificate_type_valid CHECK (
        certificate_type IN ('live', 'staged', 'self-signed', 'none', 'manual')
    ),
    CONSTRAINT service_certificates_service_name_valid CHECK (
        service_name IN ('apache', 'nginx', 'mail', 'postfix', 'dovecot', 'webdav', 'api', 'admin')
    ),
    CONSTRAINT service_certificates_health_status_valid CHECK (
        health_status IN ('healthy', 'warning', 'critical', 'unknown')
    ),
    CONSTRAINT service_certificates_hsts_max_age_positive CHECK (
        hsts_max_age IS NULL OR hsts_max_age > 0
    )
);

-- Comments for documentation
COMMENT ON TABLE unified.service_certificates IS 'Service-specific SSL/TLS certificate usage and configuration';
COMMENT ON COLUMN unified.service_certificates.certificate_type IS 'Type of certificate in use (live, staged, self-signed, none, manual)';
COMMENT ON COLUMN unified.service_certificates.ssl_protocols IS 'Enabled SSL/TLS protocols (e.g., TLSv1.2, TLSv1.3)';
COMMENT ON COLUMN unified.service_certificates.hsts_enabled IS 'Whether HTTP Strict Transport Security is enabled';
COMMENT ON COLUMN unified.service_certificates.health_status IS 'SSL health check status (healthy, warning, critical, unknown)';
COMMENT ON COLUMN unified.service_certificates.last_reload IS 'When the service last reloaded its certificate configuration';