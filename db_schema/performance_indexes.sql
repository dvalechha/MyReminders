-- ============================================
-- Performance Optimization Indexes
-- ============================================
-- These composite indexes optimize the most common queries that filter
-- by user_id and order by date/time columns.
-- 
-- Benefits:
-- 1. Faster filtering and sorting in a single index scan
-- 2. Reduced query execution time as data grows
-- 3. Better performance for RLS (Row Level Security) queries
-- ============================================

-- ============================================
-- Subscriptions: Optimize user_id + renewal_date queries
-- ============================================
-- Query pattern: SELECT * FROM subscriptions 
--                WHERE user_id = ? ORDER BY renewal_date
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_renewal_date 
    ON subscriptions(user_id, renewal_date);

-- ============================================
-- Tasks: Optimize user_id + due_date queries
-- ============================================
-- Query pattern: SELECT * FROM tasks 
--                WHERE user_id = ? ORDER BY due_date
CREATE INDEX IF NOT EXISTS idx_tasks_user_due_date 
    ON tasks(user_id, due_date);

-- ============================================
-- Appointments: Optimize user_id + start_time queries
-- ============================================
-- Query pattern: SELECT * FROM appointments 
--                WHERE user_id = ? ORDER BY start_time
CREATE INDEX IF NOT EXISTS idx_appointments_user_start_time 
    ON appointments(user_id, start_time);

-- ============================================
-- Optional: Indexes for common filter patterns
-- ============================================
-- These are optional but can help with future queries

-- For filtering subscriptions by category AND user
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_category 
    ON subscriptions(user_id, category_id);

-- For filtering tasks by category AND user
CREATE INDEX IF NOT EXISTS idx_tasks_user_category 
    ON tasks(user_id, category_id);

-- For filtering appointments by category AND user
CREATE INDEX IF NOT EXISTS idx_appointments_user_category 
    ON appointments(user_id, category_id);

-- ============================================
-- Notes on Index Strategy
-- ============================================
-- 1. Composite indexes (user_id, date) are optimal for queries that:
--    - Filter by user_id (required by RLS)
--    - Sort by date/time column
--
-- 2. The order matters: user_id first (most selective), then date
--    This allows efficient filtering then sorting
--
-- 3. These indexes work well with existing single-column indexes:
--    - user_id indexes help with user filtering
--    - date indexes help with range queries on dates
--
-- 4. Index maintenance overhead is minimal compared to query benefits
--    especially as your data grows beyond hundreds of records
--
-- 5. PostgreSQL will automatically use these indexes when appropriate
--    via its query planner
-- ============================================
