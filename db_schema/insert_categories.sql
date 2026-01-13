-- ============================================
-- Insert Subscription Categories
-- ============================================
-- This script inserts all subscription categories that appear in the Category dropdown
-- Run this script after creating the category table

-- Insert categories (using INSERT ... ON CONFLICT DO NOTHING to avoid duplicates)
INSERT INTO category (name) VALUES
  ('Entertainment'),
  ('Utilities'),
  ('Productivity'),
  ('Retail'),
  ('Health'),
  ('Travel'),
  ('Food'),
  ('Insurance'),
  ('Other')
ON CONFLICT (name) DO NOTHING;

-- Verify the insert
SELECT id, name, created_at FROM category ORDER BY name;
