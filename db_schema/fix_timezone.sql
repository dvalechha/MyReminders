-- ============================================
-- Timezone Fix Migration
-- Objective: Convert renewal_date to TIMESTAMPTZ and fix existing data
-- ============================================

BEGIN;

-- 1. Alter renewal_date column to TIMESTAMPTZ
-- We interpret the existing "Local Time" data as being in 'America/New_York' (EST/EDT)
-- This adds the correct offset before converting to UTC.
-- Example: '2026-01-13' becomes '2026-01-13 00:00:00-05' (EST) -> stored as '2026-01-13 05:00:00+00' (UTC)

ALTER TABLE subscriptions
ALTER COLUMN renewal_date TYPE TIMESTAMPTZ
USING renewal_date::timestamp AT TIME ZONE 'America/New_York';

-- 2. Verify the change (Optional, for debugging)
-- SELECT renewal_date FROM subscriptions LIMIT 5;

COMMIT;
