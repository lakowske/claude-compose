-- Migration 023: Create indexes for certificate renewals table
-- Creates performance indexes for the certificate_renewals table
-- Single-purpose: Certificate renewals table indexing only

-- Primary lookup indexes
CREATE INDEX idx_certificate_renewals_certificate_id ON unified.certificate_renewals(certificate_id);
CREATE INDEX idx_certificate_renewals_renewal_method ON unified.certificate_renewals(renewal_method);
CREATE INDEX idx_certificate_renewals_triggered_by ON unified.certificate_renewals(triggered_by);

-- Scheduling and status indexes
CREATE INDEX idx_certificate_renewals_scheduled_at ON unified.certificate_renewals(scheduled_at);
CREATE INDEX idx_certificate_renewals_started_at ON unified.certificate_renewals(started_at);
CREATE INDEX idx_certificate_renewals_completed_at ON unified.certificate_renewals(completed_at);
CREATE INDEX idx_certificate_renewals_success ON unified.certificate_renewals(success);

-- Pending renewals index
CREATE INDEX idx_certificate_renewals_pending ON unified.certificate_renewals(
    scheduled_at, started_at
) WHERE completed_at IS NULL;

-- Failed renewals index
CREATE INDEX idx_certificate_renewals_failed ON unified.certificate_renewals(
    certificate_id, success, completed_at
) WHERE success = false;

-- Recent renewals index
CREATE INDEX idx_certificate_renewals_recent ON unified.certificate_renewals(
    certificate_id, completed_at DESC
) WHERE success = true;

-- Performance tracking indexes
CREATE INDEX idx_certificate_renewals_duration ON unified.certificate_renewals(duration_seconds) 
    WHERE duration_seconds IS NOT NULL;

-- Composite indexes for common queries
CREATE INDEX idx_certificate_renewals_cert_success_completed ON unified.certificate_renewals(
    certificate_id, success, completed_at
);
CREATE INDEX idx_certificate_renewals_method_success ON unified.certificate_renewals(
    renewal_method, success
);

-- Time-based indexes
CREATE INDEX idx_certificate_renewals_created_at ON unified.certificate_renewals(created_at);