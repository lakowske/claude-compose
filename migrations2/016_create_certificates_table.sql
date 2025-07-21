-- Migration 016: Create certificates table
-- Creates core certificate management table
-- Single-purpose: Certificates table creation only

CREATE TABLE unified.certificates (
    id SERIAL PRIMARY KEY,
    domain VARCHAR(255) NOT NULL,
    certificate_type VARCHAR(50) NOT NULL,
    
    -- Certificate metadata
    subject_alt_names TEXT[],
    issuer VARCHAR(500),
    subject VARCHAR(500),
    
    -- Validity period
    not_before TIMESTAMP WITH TIME ZONE NOT NULL,
    not_after TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Certificate file paths (relative to /data/certificates/)
    certificate_path VARCHAR(500) NOT NULL,
    private_key_path VARCHAR(500) NOT NULL,
    chain_path VARCHAR(500),
    fullchain_path VARCHAR(500),
    
    -- Status and renewal tracking
    is_active BOOLEAN DEFAULT true,
    auto_renew BOOLEAN DEFAULT true,
    renewal_attempts INTEGER DEFAULT 0,
    last_renewal_attempt TIMESTAMP WITH TIME ZONE,
    last_renewal_success TIMESTAMP WITH TIME ZONE,
    renewal_error_message TEXT,
    
    -- Let's Encrypt specific fields
    acme_account_key_path VARCHAR(500),
    acme_staging BOOLEAN DEFAULT false,
    acme_challenge_type VARCHAR(50) DEFAULT 'http-01',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by INTEGER,
    
    -- Constraints
    CONSTRAINT certificates_domain_type_unique UNIQUE(domain, certificate_type),
    CONSTRAINT certificates_type_valid CHECK (
        certificate_type IN ('self-signed', 'letsencrypt', 'manual', 'ca-signed')
    ),
    CONSTRAINT certificates_validity_period CHECK (not_after > not_before),
    CONSTRAINT certificates_acme_challenge_valid CHECK (
        acme_challenge_type IN ('http-01', 'dns-01', 'tls-alpn-01')
    ),
    CONSTRAINT certificates_renewal_attempts_positive CHECK (renewal_attempts >= 0)
);

-- Add foreign key constraint
ALTER TABLE unified.certificates 
    ADD CONSTRAINT fk_certificates_created_by 
    FOREIGN KEY (created_by) REFERENCES unified.users(id) ON DELETE SET NULL;

-- Comments for documentation
COMMENT ON TABLE unified.certificates IS 'SSL/TLS certificate management with automatic renewal support';
COMMENT ON COLUMN unified.certificates.certificate_type IS 'Type of certificate (self-signed, letsencrypt, manual, ca-signed)';
COMMENT ON COLUMN unified.certificates.subject_alt_names IS 'Additional domains covered by this certificate';
COMMENT ON COLUMN unified.certificates.acme_challenge_type IS 'ACME challenge method (http-01, dns-01, tls-alpn-01)';
COMMENT ON COLUMN unified.certificates.acme_staging IS 'Whether to use Let''s Encrypt staging environment';
COMMENT ON COLUMN unified.certificates.renewal_attempts IS 'Number of failed renewal attempts for this certificate';