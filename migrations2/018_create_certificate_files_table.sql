-- Migration 018: Create certificate files table
-- Creates table for individual certificate files with integrity verification
-- Single-purpose: Certificate files table creation only

CREATE TABLE unified.certificate_files (
    id SERIAL PRIMARY KEY,
    certificate_id INTEGER NOT NULL,
    
    -- File details
    file_type VARCHAR(50) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    file_size BIGINT NOT NULL,
    file_checksum VARCHAR(64) NOT NULL,
    file_permissions VARCHAR(10) NOT NULL,
    
    -- Verification status
    last_verified TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    verification_status VARCHAR(20) DEFAULT 'verified',
    verification_error TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT certificate_files_cert_file_type_unique UNIQUE(certificate_id, file_type),
    CONSTRAINT certificate_files_file_type_valid CHECK (
        file_type IN ('certificate', 'private_key', 'chain', 'fullchain', 'csr', 'account_key')
    ),
    CONSTRAINT certificate_files_permissions_valid CHECK (file_permissions ~ '^[0-7]{3}$'),
    CONSTRAINT certificate_files_size_positive CHECK (file_size >= 0),
    CONSTRAINT certificate_files_checksum_format CHECK (file_checksum ~ '^[a-f0-9]{64}$'),
    CONSTRAINT certificate_files_verification_status_valid CHECK (
        verification_status IN ('verified', 'needs_verification', 'failed', 'missing')
    )
);

-- Add foreign key constraint
ALTER TABLE unified.certificate_files 
    ADD CONSTRAINT fk_certificate_files_certificate_id 
    FOREIGN KEY (certificate_id) REFERENCES unified.certificates(id) ON DELETE CASCADE;

-- Comments for documentation
COMMENT ON TABLE unified.certificate_files IS 'Individual certificate files with integrity verification';
COMMENT ON COLUMN unified.certificate_files.file_type IS 'Type of certificate file (certificate, private_key, chain, fullchain, csr, account_key)';
COMMENT ON COLUMN unified.certificate_files.file_checksum IS 'SHA256 checksum for file integrity verification';
COMMENT ON COLUMN unified.certificate_files.file_permissions IS 'File permissions in octal format (e.g., 644, 600)';
COMMENT ON COLUMN unified.certificate_files.verification_status IS 'File verification status (verified, needs_verification, failed, missing)';