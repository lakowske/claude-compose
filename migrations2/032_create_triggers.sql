-- Migration 032: Create triggers for automated operations
-- Creates triggers for timestamp updates, notifications, and domain extraction
-- Single-purpose: Triggers creation only

-- ================================================================
-- USER TABLE TRIGGERS
-- ================================================================

-- Trigger to extract domain from email and set home directory
CREATE TRIGGER trigger_users_extract_domain_email
    BEFORE INSERT OR UPDATE ON unified.users
    FOR EACH ROW
    EXECUTE FUNCTION unified.extract_domain_from_email();

-- Trigger to update updated_at timestamp
CREATE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON unified.users
    FOR EACH ROW
    EXECUTE FUNCTION unified.update_updated_at_column();

-- Trigger to notify user changes
CREATE TRIGGER trigger_users_notify_changes
    AFTER INSERT OR UPDATE OR DELETE ON unified.users
    FOR EACH ROW
    EXECUTE FUNCTION unified.notify_user_changes();

-- ================================================================
-- USER PASSWORDS TABLE TRIGGERS
-- ================================================================

CREATE TRIGGER trigger_user_passwords_updated_at
    BEFORE UPDATE ON unified.user_passwords
    FOR EACH ROW
    EXECUTE FUNCTION unified.update_updated_at_column();

-- ================================================================
-- USER QUOTAS TABLE TRIGGERS
-- ================================================================

CREATE TRIGGER trigger_user_quotas_updated_at
    BEFORE UPDATE ON unified.user_quotas
    FOR EACH ROW
    EXECUTE FUNCTION unified.update_updated_at_column();

-- ================================================================
-- EMAIL ALIASES TABLE TRIGGERS
-- ================================================================

CREATE TRIGGER trigger_email_aliases_updated_at
    BEFORE UPDATE ON unified.email_aliases
    FOR EACH ROW
    EXECUTE FUNCTION unified.update_updated_at_column();

-- ================================================================
-- CERTIFICATES TABLE TRIGGERS
-- ================================================================

CREATE TRIGGER trigger_certificates_updated_at
    BEFORE UPDATE ON unified.certificates
    FOR EACH ROW
    EXECUTE FUNCTION unified.update_updated_at_column();

CREATE TRIGGER trigger_certificates_notify_changes
    AFTER INSERT OR UPDATE OR DELETE ON unified.certificates
    FOR EACH ROW
    EXECUTE FUNCTION unified.notify_certificate_changes();

-- ================================================================
-- CERTIFICATE FILES TABLE TRIGGERS
-- ================================================================

CREATE TRIGGER trigger_certificate_files_updated_at
    BEFORE UPDATE ON unified.certificate_files
    FOR EACH ROW
    EXECUTE FUNCTION unified.update_updated_at_column();

-- ================================================================
-- SERVICE CERTIFICATES TABLE TRIGGERS
-- ================================================================

CREATE TRIGGER trigger_service_certificates_updated_at
    BEFORE UPDATE ON unified.service_certificates
    FOR EACH ROW
    EXECUTE FUNCTION unified.update_updated_at_column();

-- ================================================================
-- DNS ZONES TABLE TRIGGERS
-- ================================================================

CREATE TRIGGER trigger_dns_zones_updated_at
    BEFORE UPDATE ON unified.dns_zones
    FOR EACH ROW
    EXECUTE FUNCTION unified.update_updated_at_column();

-- ================================================================
-- DNS RECORDS TABLE TRIGGERS
-- ================================================================

CREATE TRIGGER trigger_dns_records_updated_at
    BEFORE UPDATE ON unified.dns_records
    FOR EACH ROW
    EXECUTE FUNCTION unified.update_updated_at_column();

-- Trigger to update DNS zone serial when records change
CREATE TRIGGER trigger_dns_records_update_zone_serial
    AFTER INSERT OR UPDATE OR DELETE ON unified.dns_records
    FOR EACH ROW
    EXECUTE FUNCTION unified.update_dns_zone_serial();

-- Comments for documentation
COMMENT ON TRIGGER trigger_users_extract_domain_email ON unified.users IS 'Extracts domain from email and sets home directory';
COMMENT ON TRIGGER trigger_users_notify_changes ON unified.users IS 'Sends notifications for user changes via LISTEN/NOTIFY';
COMMENT ON TRIGGER trigger_certificates_notify_changes ON unified.certificates IS 'Sends notifications for certificate changes';
COMMENT ON TRIGGER trigger_dns_records_update_zone_serial ON unified.dns_records IS 'Updates DNS zone serial number when records change';