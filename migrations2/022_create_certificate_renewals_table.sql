-- Migration 022: Create certificate renewals table
-- Creates certificate renewal schedule and history table
-- Single-purpose: Certificate renewals table creation only

CREATE TABLE unified.certificate_renewals (
    id SERIAL PRIMARY KEY,
    certificate_id INTEGER NOT NULL,
    
    -- Renewal scheduling
    scheduled_at TIMESTAMP WITH TIME ZONE NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Renewal details
    renewal_method VARCHAR(50) NOT NULL,
    success BOOLEAN,
    error_message TEXT,
    
    -- Certificate validity tracking
    old_not_after TIMESTAMP WITH TIME ZONE,
    new_not_after TIMESTAMP WITH TIME ZONE,
    
    -- Renewal context
    triggered_by VARCHAR(100),
    renewal_logs TEXT,
    
    -- Performance tracking
    duration_seconds INTEGER,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT certificate_renewals_renewal_method_valid CHECK (
        renewal_method IN ('automatic', 'manual', 'forced', 'emergency')
    ),
    CONSTRAINT certificate_renewals_duration_positive CHECK (
        duration_seconds IS NULL OR duration_seconds >= 0
    ),
    CONSTRAINT certificate_renewals_validity_check CHECK (
        old_not_after IS NULL OR new_not_after IS NULL OR new_not_after > old_not_after
    )
);

-- Add foreign key constraint
ALTER TABLE unified.certificate_renewals 
    ADD CONSTRAINT fk_certificate_renewals_certificate_id 
    FOREIGN KEY (certificate_id) REFERENCES unified.certificates(id) ON DELETE CASCADE;

-- Comments for documentation
COMMENT ON TABLE unified.certificate_renewals IS 'Certificate renewal scheduling and history tracking';
COMMENT ON COLUMN unified.certificate_renewals.renewal_method IS 'How renewal was triggered (automatic, manual, forced, emergency)';
COMMENT ON COLUMN unified.certificate_renewals.triggered_by IS 'What triggered the renewal (cron, api, expiration_check, user_request)';
COMMENT ON COLUMN unified.certificate_renewals.duration_seconds IS 'Time taken to complete the renewal process';
COMMENT ON COLUMN unified.certificate_renewals.renewal_logs IS 'Detailed logs from the renewal process';