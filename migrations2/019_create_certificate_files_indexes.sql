-- Migration 019: Create indexes for certificate files table
-- Creates performance indexes for the certificate_files table
-- Single-purpose: Certificate files table indexing only

-- Primary lookup indexes
CREATE INDEX idx_certificate_files_certificate_id ON unified.certificate_files(certificate_id);
CREATE INDEX idx_certificate_files_file_type ON unified.certificate_files(file_type);
CREATE INDEX idx_certificate_files_file_path ON unified.certificate_files(file_path);

-- Verification indexes
CREATE INDEX idx_certificate_files_verification_status ON unified.certificate_files(verification_status);
CREATE INDEX idx_certificate_files_last_verified ON unified.certificate_files(last_verified);
CREATE INDEX idx_certificate_files_needs_verification ON unified.certificate_files(last_verified) 
    WHERE verification_status = 'needs_verification';

-- File integrity indexes
CREATE INDEX idx_certificate_files_file_checksum ON unified.certificate_files(file_checksum);
CREATE INDEX idx_certificate_files_file_size ON unified.certificate_files(file_size);

-- Composite indexes for common queries
CREATE INDEX idx_certificate_files_cert_type ON unified.certificate_files(certificate_id, file_type);
CREATE INDEX idx_certificate_files_type_status ON unified.certificate_files(file_type, verification_status);

-- Verification monitoring index
CREATE INDEX idx_certificate_files_stale_verification ON unified.certificate_files(
    certificate_id, last_verified
) WHERE verification_status != 'verified' OR last_verified < (CURRENT_TIMESTAMP - INTERVAL '24 hours');

-- Timestamp indexes
CREATE INDEX idx_certificate_files_created_at ON unified.certificate_files(created_at);
CREATE INDEX idx_certificate_files_updated_at ON unified.certificate_files(updated_at);