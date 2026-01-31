-- Add is_completed column to appointments table
ALTER TABLE appointments ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT FALSE;
