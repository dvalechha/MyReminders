# Supabase Database Setup

## Schema Location

The database schema is defined in `reminders_schema.sql`. This file contains the complete DDL for setting up the Supabase Postgres database.

## Setup Instructions

1. **Copy the SQL schema**:
   - Open `reminders_schema.sql`
   - Copy the entire contents

2. **Run in Supabase SQL Editor**:
   - Go to your Supabase project dashboard
   - Navigate to SQL Editor
   - Paste the SQL schema
   - Execute the script

3. **Verify tables are created**:
   - Check that all 5 tables are created in the `public` schema:
     - `category`
     - `subscriptions`
     - `appointments`
     - `tasks`
     - `custom_reminder`

## Important Notes

### Schema Format in Flutter Code

The repositories use the table name directly (e.g., `'category'`) since tables are in the default `public` schema. No additional configuration is needed.

### Row Level Security (RLS)

All tables have RLS enabled with policies that ensure:
- Users can only access their own data (filtered by `user_id`)
- Categories are readable by all authenticated users
- All operations (SELECT, INSERT, UPDATE, DELETE) are properly secured

### Initial Category Data

The `category` table is empty by default. You'll need to insert initial category data manually or via a migration script.

Example:
```sql
INSERT INTO category (name) VALUES
  ('Entertainment'),
  ('Utilities'),
  ('Productivity'),
  ('Retail');
```


