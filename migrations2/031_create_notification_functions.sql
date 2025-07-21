-- Migration 031: Create notification functions
-- Creates functions for LISTEN/NOTIFY system
-- Single-purpose: Notification functions creation only

-- Function to notify when users are created, updated, or deleted
CREATE OR REPLACE FUNCTION unified.notify_user_changes()
RETURNS TRIGGER AS $$
DECLARE
    notification_channel TEXT;
    notification_data JSONB;
BEGIN
    -- Determine notification channel based on operation
    notification_channel = CASE TG_OP
        WHEN 'INSERT' THEN 'user_created'
        WHEN 'UPDATE' THEN 'user_updated'
        WHEN 'DELETE' THEN 'user_deleted'
    END;
    
    -- Prepare notification data
    IF TG_OP = 'DELETE' THEN
        notification_data = jsonb_build_object(
            'user_id', OLD.id,
            'username', OLD.username,
            'email', OLD.email,
            'domain', OLD.domain,
            'home_directory', OLD.home_directory,
            'operation', TG_OP,
            'timestamp', CURRENT_TIMESTAMP
        );
    ELSIF TG_OP = 'UPDATE' THEN
        -- Only notify for significant changes
        IF NEW.email != OLD.email OR NEW.domain != OLD.domain OR NEW.home_directory != OLD.home_directory THEN
            notification_data = jsonb_build_object(
                'user_id', NEW.id,
                'username', NEW.username,
                'old_email', OLD.email,
                'new_email', NEW.email,
                'old_domain', OLD.domain,
                'new_domain', NEW.domain,
                'old_home_directory', OLD.home_directory,
                'new_home_directory', NEW.home_directory,
                'operation', TG_OP,
                'timestamp', CURRENT_TIMESTAMP
            );
        ELSE
            RETURN NEW; -- No notification needed
        END IF;
    ELSE -- INSERT
        notification_data = jsonb_build_object(
            'user_id', NEW.id,
            'username', NEW.username,
            'email', NEW.email,
            'domain', NEW.domain,
            'home_directory', NEW.home_directory,
            'operation', TG_OP,
            'timestamp', CURRENT_TIMESTAMP
        );
    END IF;
    
    -- Send PostgreSQL notification
    PERFORM pg_notify(notification_channel, notification_data::text);
    
    -- Log to mailbox_events table
    INSERT INTO unified.mailbox_events (
        event_type,
        user_id,
        username,
        email,
        domain,
        home_directory,
        event_data
    ) VALUES (
        CASE TG_OP
            WHEN 'INSERT' THEN 'created'
            WHEN 'UPDATE' THEN 'updated'
            WHEN 'DELETE' THEN 'deleted'
        END,
        COALESCE(NEW.id, OLD.id),
        COALESCE(NEW.username, OLD.username),
        COALESCE(NEW.email, OLD.email),
        COALESCE(NEW.domain, OLD.domain),
        COALESCE(NEW.home_directory, OLD.home_directory),
        notification_data
    );
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Function to notify certificate changes
CREATE OR REPLACE FUNCTION unified.notify_certificate_changes()
RETURNS TRIGGER AS $$
DECLARE
    notification_type VARCHAR(50);
    notification_data JSONB;
BEGIN
    -- Determine notification type
    notification_type = CASE TG_OP
        WHEN 'INSERT' THEN 'created'
        WHEN 'UPDATE' THEN 'updated'
        WHEN 'DELETE' THEN 'deleted'
    END;
    
    -- Prepare notification data
    notification_data = jsonb_build_object(
        'certificate_id', COALESCE(NEW.id, OLD.id),
        'domain', COALESCE(NEW.domain, OLD.domain),
        'certificate_type', COALESCE(NEW.certificate_type, OLD.certificate_type),
        'operation', TG_OP,
        'timestamp', CURRENT_TIMESTAMP
    );
    
    -- Insert notification record
    INSERT INTO unified.certificate_notifications (
        certificate_id,
        notification_type,
        message,
        notification_data
    ) VALUES (
        COALESCE(NEW.id, OLD.id),
        notification_type,
        format('Certificate %s for domain %s', notification_type, COALESCE(NEW.domain, OLD.domain)),
        notification_data
    );
    
    -- Send PostgreSQL notification
    PERFORM pg_notify('certificate_changes', notification_data::text);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Comments for documentation
COMMENT ON FUNCTION unified.notify_user_changes() IS 'Sends notifications for user create/update/delete operations';
COMMENT ON FUNCTION unified.notify_certificate_changes() IS 'Sends notifications for certificate changes';