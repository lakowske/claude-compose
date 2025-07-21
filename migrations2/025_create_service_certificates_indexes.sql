-- Migration 025: Create indexes for service certificates table
-- Creates performance indexes for the service_certificates table
-- Single-purpose: Service certificates table indexing only

-- Primary lookup indexes
CREATE INDEX idx_service_certificates_service_name ON unified.service_certificates(service_name);
CREATE INDEX idx_service_certificates_domain ON unified.service_certificates(domain);
CREATE INDEX idx_service_certificates_certificate_type ON unified.service_certificates(certificate_type);

-- Status indexes
CREATE INDEX idx_service_certificates_is_active ON unified.service_certificates(is_active);
CREATE INDEX idx_service_certificates_ssl_enabled ON unified.service_certificates(ssl_enabled);
CREATE INDEX idx_service_certificates_health_status ON unified.service_certificates(health_status);

-- Configuration indexes
CREATE INDEX idx_service_certificates_hsts_enabled ON unified.service_certificates(hsts_enabled) 
    WHERE hsts_enabled = true;

-- Health monitoring indexes
CREATE INDEX idx_service_certificates_last_health_check ON unified.service_certificates(last_health_check);
CREATE INDEX idx_service_certificates_health_errors ON unified.service_certificates(health_error) 
    WHERE health_error IS NOT NULL;

-- Composite indexes for common queries
CREATE INDEX idx_service_certificates_service_domain ON unified.service_certificates(service_name, domain);
CREATE INDEX idx_service_certificates_service_active ON unified.service_certificates(service_name, is_active);
CREATE INDEX idx_service_certificates_domain_active ON unified.service_certificates(domain, is_active);
CREATE INDEX idx_service_certificates_ssl_active ON unified.service_certificates(ssl_enabled, is_active);

-- Certificate type and service queries
CREATE INDEX idx_service_certificates_type_service ON unified.service_certificates(certificate_type, service_name);

-- Time-based indexes
CREATE INDEX idx_service_certificates_last_updated ON unified.service_certificates(last_updated);
CREATE INDEX idx_service_certificates_last_reload ON unified.service_certificates(last_reload);
CREATE INDEX idx_service_certificates_created_at ON unified.service_certificates(created_at);