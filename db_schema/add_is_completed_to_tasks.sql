-- Add is_completed column to tasks table
-- This fixes an issue where tasks were failing to save to Supabase due to missing column
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT FALSE;
