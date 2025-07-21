-- Migration 033: Create service compatibility views
-- Creates views for service integration (Apache, Dovecot, etc.)
-- Single-purpose: Service integration views creation only

-- ================================================================
-- APACHE AUTHENTICATION VIEWS
-- ================================================================

-- Apache authentication view for mod_authn_dbd
CREATE VIEW unified.apache_auth AS
SELECT
    u.username,
    up.password_hash as password,
    CASE 
        WHEN ur.role_name = 'admin' THEN 'admin'
        WHEN ur.role_name = 'user' THEN 'user'
        ELSE 'customer' 
    END as role,
    u.is_active,
    u.email_verified,
    u.email
FROM unified.users u
    JOIN unified.user_passwords up ON u.id = up.user_id
    LEFT JOIN unified.user_roles ur ON u.id = ur.user_id 
        AND ur.service = 'apache' 
        AND ur.is_active = true
WHERE u.is_active = true
    AND u.email_verified = true
    AND up.service = 'apache';

-- ================================================================
-- DOVECOT AUTHENTICATION VIEWS
-- ================================================================

-- Dovecot password authentication view
CREATE VIEW unified.dovecot_auth AS
SELECT
    u.username,
    u.domain,
    u.email as "user",
    up.password_hash as password,
    up.hash_scheme as scheme,
    u.is_active
FROM unified.users u
    JOIN unified.user_passwords up ON u.id = up.user_id
    LEFT JOIN unified.user_roles ur ON u.id = ur.user_id 
        AND ur.service = 'dovecot' 
        AND ur.is_active = true
WHERE u.is_active = true
    AND up.service = 'dovecot'
    AND (ur.role_name IS NULL OR ur.role_name != 'no_email');

-- Dovecot user information view
CREATE VIEW unified.dovecot_users AS
SELECT
    u.username,
    u.domain,
    u.email as "user",
    u.home_directory as home,
    u.system_uid as uid,
    u.system_gid as gid,
    u.mailbox_format,
    COALESCE(q.quota_value, 1073741824) as quota_bytes -- default 1GB
FROM unified.users u
    LEFT JOIN unified.user_quotas q ON u.id = q.user_id
        AND q.service = 'dovecot'
        AND q.quota_type = 'storage'
WHERE u.is_active = true;

-- ================================================================
-- CERTIFICATE STATUS VIEWS
-- ================================================================

-- Active certificates with expiration status
CREATE VIEW unified.certificate_status AS
SELECT
    c.id,
    c.domain,
    c.certificate_type,
    c.subject_alt_names,
    c.issuer,
    c.not_before,
    c.not_after,
    c.is_active,
    c.auto_renew,
    c.last_renewal_success,
    c.renewal_error_message,
    
    -- Expiration calculations
    (c.not_after - CURRENT_TIMESTAMP) AS time_until_expiry,
    CASE
        WHEN c.not_after < CURRENT_TIMESTAMP THEN 'expired'
        WHEN c.not_after < (CURRENT_TIMESTAMP + INTERVAL '7 days') THEN 'critical'
        WHEN c.not_after < (CURRENT_TIMESTAMP + INTERVAL '30 days') THEN 'warning'
        ELSE 'valid'
    END AS expiry_status,
    
    -- File paths for easy access
    c.certificate_path,
    c.private_key_path,
    c.fullchain_path,
    
    -- Renewal information
    (SELECT COUNT(*) 
     FROM unified.certificate_renewals cr
     WHERE cr.certificate_id = c.id 
         AND cr.success = false
         AND cr.created_at > CURRENT_TIMESTAMP - INTERVAL '30 days'
    ) AS recent_failed_renewals
FROM unified.certificates c
WHERE c.is_active = true
ORDER BY c.not_after ASC;

-- Certificate files with verification status
CREATE VIEW unified.certificate_file_status AS
SELECT
    c.domain,
    c.certificate_type,
    cf.file_type,
    cf.file_path,
    cf.file_size,
    cf.file_checksum,
    cf.file_permissions,
    cf.last_verified,
    cf.verification_status,
    (CURRENT_TIMESTAMP - cf.last_verified) AS time_since_verification
FROM unified.certificates c
    JOIN unified.certificate_files cf ON c.id = cf.certificate_id
WHERE c.is_active = true
ORDER BY c.domain, cf.file_type;

-- ================================================================
-- EMAIL AND ALIAS VIEWS
-- ================================================================

-- Active email aliases for mail routing
CREATE VIEW unified.mail_aliases AS
SELECT
    ea.alias_email,
    ea.destination_email,
    u.username,
    u.domain,
    ea.is_primary,
    ea.is_catch_all,
    ea.created_at
FROM unified.email_aliases ea
    JOIN unified.users u ON ea.user_id = u.id
WHERE ea.is_active = true
    AND u.is_active = true
ORDER BY ea.alias_email;

-- ================================================================
-- AUDIT AND MONITORING VIEWS
-- ================================================================

-- Recent audit events summary
CREATE VIEW unified.audit_summary AS
SELECT
    DATE_TRUNC('hour', created_at) as event_hour,
    service,
    action,
    success,
    COUNT(*) as event_count,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(DISTINCT ip_address) as unique_ips
FROM unified.audit_log
WHERE created_at > CURRENT_TIMESTAMP - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', created_at), service, action, success
ORDER BY event_hour DESC, event_count DESC;

-- Comments for documentation
COMMENT ON VIEW unified.apache_auth IS 'Apache authentication data for mod_authn_dbd integration';
COMMENT ON VIEW unified.dovecot_auth IS 'Dovecot password authentication data';
COMMENT ON VIEW unified.dovecot_users IS 'Dovecot user information with quotas and mailbox settings';
COMMENT ON VIEW unified.certificate_status IS 'Certificate status with expiration monitoring';
COMMENT ON VIEW unified.certificate_file_status IS 'Certificate file verification status';
COMMENT ON VIEW unified.mail_aliases IS 'Active email aliases for mail routing';
COMMENT ON VIEW unified.audit_summary IS 'Hourly audit event summary for monitoring';