-- Migration 017: Create indexes for certificates table
-- Creates performance indexes for the certificates table
-- Single-purpose: Certificates table indexing only

-- Primary lookup indexes
CREATE INDEX idx_certificates_domain ON unified.certificates(domain);
CREATE INDEX idx_certificates_certificate_type ON unified.certificates(certificate_type);
CREATE INDEX idx_certificates_created_by ON unified.certificates(created_by);

-- Status indexes
CREATE INDEX idx_certificates_is_active ON unified.certificates(is_active);
CREATE INDEX idx_certificates_auto_renew ON unified.certificates(auto_renew);

-- Expiration monitoring indexes
CREATE INDEX idx_certificates_not_after ON unified.certificates(not_after);
CREATE INDEX idx_certificates_expiry_active ON unified.certificates(not_after, is_active) 
    WHERE is_active = true;

-- Renewal tracking indexes
CREATE INDEX idx_certificates_last_renewal_attempt ON unified.certificates(last_renewal_attempt);
CREATE INDEX idx_certificates_last_renewal_success ON unified.certificates(last_renewal_success);
CREATE INDEX idx_certificates_renewal_attempts ON unified.certificates(renewal_attempts);

-- Let's Encrypt specific indexes
CREATE INDEX idx_certificates_acme_staging ON unified.certificates(acme_staging) 
    WHERE certificate_type = 'letsencrypt';
CREATE INDEX idx_certificates_acme_challenge_type ON unified.certificates(acme_challenge_type) 
    WHERE certificate_type = 'letsencrypt';

-- Composite indexes for common queries
CREATE INDEX idx_certificates_domain_active ON unified.certificates(domain, is_active);
CREATE INDEX idx_certificates_type_active ON unified.certificates(certificate_type, is_active);

-- Expiration status composite index
CREATE INDEX idx_certificates_expiry_status ON unified.certificates(
    CASE 
        WHEN not_after < CURRENT_TIMESTAMP THEN 'expired'
        WHEN not_after < (CURRENT_TIMESTAMP + INTERVAL '7 days') THEN 'critical'
        WHEN not_after < (CURRENT_TIMESTAMP + INTERVAL '30 days') THEN 'warning'
        ELSE 'valid'
    END,
    not_after
) WHERE is_active = true;

-- Timestamp indexes
CREATE INDEX idx_certificates_created_at ON unified.certificates(created_at);
CREATE INDEX idx_certificates_updated_at ON unified.certificates(updated_at);