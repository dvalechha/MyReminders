**Context:**
I am experiencing a critical Timezone/UTC mismatch bug. My application shows items as "Due Today" or "Past Due" incorrectly because the `renewal_date` was saved as Local Time, but the database/query logic treats it as UTC (or uses naive timestamps).

**Objective:**
I need to enforce strict UTC handling across the Database, API, and Query logic to ensure "Due Date" comparisons are accurate regardless of the user's local timezone.

**My Tech Stack:**
* **Database:** Supabase (PostgreSQL)
* **Frontend/Backend:** [Insert your framework here, e.g., Next.js / React / Node.js]

**Please provide the code and SQL for the following 3 fixes:**

### 1. Database Schema & Data Migration (SQL)
* **Schema Change:** Provide the SQL to alter the `renewal_date` column to use `TIMESTAMPTZ` (Timestamp with Time Zone).
* **Data Repair:** I have existing records stored as "Local Time" (e.g., `2026-01-13 17:00:00`) without an offset. Provide a SQL query to convert these specific records to valid UTC by adding the correct offset (assume the data was entered in **[Insert your Timezone, e.g., EST/UTC-5]**).

### 2. The "Write" Logic (Backend)
* Review the standard saving function.
* Show me how to sanitize the date immediately upon request. Ensure that `renewal_date` is converted to a strict ISO-8601 UTC string (e.g., `.toISOString()`) *before* it is sent to the database.

### 3. The "Read" Comparison Logic (Query)
* Fix the specific SQL or filter logic used to determine if an item is "Due".
* Ensure we are comparing the stored `renewal_date` against `NOW() AT TIME ZONE 'UTC'` (or the framework equivalent) so the comparison is strictly UTC-to-UTC.