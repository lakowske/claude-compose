-- Migration 001: Create unified schema
-- Creates the unified schema for the application
-- Single-purpose: Schema creation only

CREATE SCHEMA IF NOT EXISTS unified;

-- Add comments for documentation
COMMENT ON SCHEMA unified IS 'Main application schema for unified user and service management';