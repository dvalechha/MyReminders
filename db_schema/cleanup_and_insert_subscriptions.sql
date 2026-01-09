-- ============================================
-- Cleanup and Insert Subscription Test Data
-- ============================================
-- This script:
-- 1. Deletes all existing subscriptions for the test user
-- 2. Inserts fresh test data with Orange and Green status subscriptions
-- ============================================

-- Hard-coded values
-- user_id: b067789d-3164-485c-8f09-8f1ba92c8d2c

-- Step 1: Cleanup - Delete existing subscriptions for this user
DELETE FROM subscriptions 
WHERE user_id = 'b067789d-3164-485c-8f09-8f1ba92c8d2c';

-- Step 2: Insert new test data (Orange & Green status only)
-- Orange Status Subscriptions (Renewals in 0-7 days)
INSERT INTO subscriptions (user_id, category_id, title, amount, currency, renewal_date, billing_cycle, reminder_days_before, payment_last4, notes, created_at, updated_at) VALUES
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Netflix', 15.99, 'USD', CURRENT_DATE, 'monthly', 3, '4242', 'Standard plan - Renews today', NOW() - INTERVAL '30 days', NOW() - INTERVAL '30 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Spotify Premium', 9.99, 'USD', CURRENT_DATE + INTERVAL '1 day', 'monthly', 1, '1234', 'Renews tomorrow', NOW() - INTERVAL '25 days', NOW() - INTERVAL '25 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Disney+', 10.99, 'USD', CURRENT_DATE + INTERVAL '2 days', 'monthly', 3, NULL, NULL, NOW() - INTERVAL '28 days', NOW() - INTERVAL '28 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Apple Music', 10.99, 'USD', CURRENT_DATE + INTERVAL '3 days', 'monthly', 1, '7890', NULL, NOW() - INTERVAL '22 days', NOW() - INTERVAL '22 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Amazon Prime', 14.99, 'USD', CURRENT_DATE + INTERVAL '4 days', 'monthly', 5, '9012', NULL, NOW() - INTERVAL '15 days', NOW() - INTERVAL '15 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'YouTube Premium', 13.99, 'USD', CURRENT_DATE + INTERVAL '5 days', 'monthly', 2, '2468', NULL, NOW() - INTERVAL '18 days', NOW() - INTERVAL '18 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Dropbox Plus', 9.99, 'USD', CURRENT_DATE + INTERVAL '6 days', 'monthly', 3, '9876', '2TB storage', NOW() - INTERVAL '16 days', NOW() - INTERVAL '16 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Notion Pro', 8.00, 'USD', CURRENT_DATE + INTERVAL '7 days', 'monthly', 2, '1111', NULL, NOW() - INTERVAL '14 days', NOW() - INTERVAL '14 days'),

-- Green Status Subscriptions (Renewals >7 days)
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Adobe Creative Cloud', 52.99, 'USD', CURRENT_DATE + INTERVAL '10 days', 'monthly', 7, '5678', 'Annual plan, billed monthly', NOW() - INTERVAL '20 days', NOW() - INTERVAL '20 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Microsoft 365', 6.99, 'USD', CURRENT_DATE + INTERVAL '15 days', 'monthly', 2, '3456', 'Personal subscription', NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'HBO Max', 15.99, 'USD', CURRENT_DATE + INTERVAL '20 days', 'monthly', 5, '1357', NULL, NOW() - INTERVAL '12 days', NOW() - INTERVAL '12 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'iCloud Storage', 0.99, 'USD', CURRENT_DATE + INTERVAL '12 days', 'monthly', 0, NULL, '50GB plan', NOW() - INTERVAL '35 days', NOW() - INTERVAL '35 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'GitHub Pro', 4.00, 'USD', CURRENT_DATE + INTERVAL '18 days', 'monthly', 1, '5432', NULL, NOW() - INTERVAL '8 days', NOW() - INTERVAL '8 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Figma Professional', 12.00, 'USD', CURRENT_DATE + INTERVAL '22 days', 'monthly', 7, '2222', NULL, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'LinkedIn Premium', 29.99, 'USD', CURRENT_DATE + INTERVAL '25 days', 'monthly', 5, '3333', 'Career plan', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Audible', 14.95, 'USD', CURRENT_DATE + INTERVAL '30 days', 'monthly', 1, '4444', NULL, NOW() - INTERVAL '32 days', NOW() - INTERVAL '32 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Hulu', 7.99, 'USD', CURRENT_DATE + INTERVAL '35 days', 'monthly', 2, '5555', 'Basic plan', NOW() - INTERVAL '24 days', NOW() - INTERVAL '24 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Paramount+', 5.99, 'USD', CURRENT_DATE + INTERVAL '40 days', 'monthly', 1, NULL, NULL, NOW() - INTERVAL '9 days', NOW() - INTERVAL '9 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Apple TV+', 6.99, 'USD', CURRENT_DATE + INTERVAL '45 days', 'monthly', 3, '6666', NULL, NOW() - INTERVAL '27 days', NOW() - INTERVAL '27 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Shutterstock', 29.99, 'USD', CURRENT_DATE + INTERVAL '50 days', 'monthly', 7, '7777', '10 images per month', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Canva Pro', 12.99, 'USD', CURRENT_DATE + INTERVAL '55 days', 'monthly', 2, '8888', NULL, NOW() - INTERVAL '13 days', NOW() - INTERVAL '13 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Zoom Pro', 14.99, 'USD', CURRENT_DATE + INTERVAL '60 days', 'monthly', 5, '9999', NULL, NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Slack Pro', 7.25, 'USD', CURRENT_DATE + INTERVAL '65 days', 'monthly', 1, '0000', NULL, NOW() - INTERVAL '23 days', NOW() - INTERVAL '23 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Evernote Premium', 7.99, 'USD', CURRENT_DATE + INTERVAL '70 days', 'monthly', 3, '1212', NULL, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Grammarly Premium', 12.00, 'USD', CURRENT_DATE + INTERVAL '75 days', 'monthly', 2, '3434', NULL, NOW() - INTERVAL '17 days', NOW() - INTERVAL '17 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', '1Password', 2.99, 'USD', CURRENT_DATE + INTERVAL '80 days', 'monthly', 1, '5656', 'Individual plan', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'LastPass Premium', 3.00, 'USD', CURRENT_DATE + INTERVAL '85 days', 'monthly', 0, '7878', NULL, NOW() - INTERVAL '33 days', NOW() - INTERVAL '33 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'NordVPN', 11.95, 'USD', CURRENT_DATE + INTERVAL '90 days', 'monthly', 5, '9090', NULL, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Surfshark', 12.95, 'USD', CURRENT_DATE + INTERVAL '95 days', 'monthly', 3, NULL, NULL, NOW() - INTERVAL '31 days', NOW() - INTERVAL '31 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'ExpressVPN', 12.95, 'USD', CURRENT_DATE + INTERVAL '100 days', 'monthly', 7, '2323', NULL, NOW() - INTERVAL '11 days', NOW() - INTERVAL '11 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Crunchyroll Premium', 7.99, 'USD', CURRENT_DATE + INTERVAL '105 days', 'monthly', 2, '4545', NULL, NOW() - INTERVAL '21 days', NOW() - INTERVAL '21 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Twitch Turbo', 8.99, 'USD', CURRENT_DATE + INTERVAL '110 days', 'monthly', 1, '6767', NULL, NOW() - INTERVAL '0 days', NOW() - INTERVAL '0 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Discord Nitro', 9.99, 'USD', CURRENT_DATE + INTERVAL '115 days', 'monthly', 3, '8989', NULL, NOW() - INTERVAL '19 days', NOW() - INTERVAL '19 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Strava Premium', 5.00, 'USD', CURRENT_DATE + INTERVAL '120 days', 'monthly', 5, NULL, NULL, NOW() - INTERVAL '29 days', NOW() - INTERVAL '29 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'MyFitnessPal Premium', 9.99, 'USD', CURRENT_DATE + INTERVAL '125 days', 'monthly', 0, '1010', NULL, NOW() - INTERVAL '34 days', NOW() - INTERVAL '34 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Headspace', 12.99, 'USD', CURRENT_DATE + INTERVAL '130 days', 'monthly', 7, '2020', NULL, NOW() - INTERVAL '26 days', NOW() - INTERVAL '26 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Calm Premium', 14.99, 'USD', CURRENT_DATE + INTERVAL '135 days', 'monthly', 0, '3030', NULL, NOW() - INTERVAL '36 days', NOW() - INTERVAL '36 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Duolingo Plus', 6.99, 'USD', CURRENT_DATE + INTERVAL '140 days', 'monthly', 1, '4040', NULL, NOW() - INTERVAL '37 days', NOW() - INTERVAL '37 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Babbel', 13.95, 'USD', CURRENT_DATE + INTERVAL '145 days', 'monthly', 3, '5050', NULL, NOW() - INTERVAL '38 days', NOW() - INTERVAL '38 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'MasterClass', 15.00, 'USD', CURRENT_DATE + INTERVAL '150 days', 'monthly', 5, '6060', NULL, NOW() - INTERVAL '39 days', NOW() - INTERVAL '39 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Skillshare', 32.00, 'USD', CURRENT_DATE + INTERVAL '180 days', 'monthly', 7, '7070', 'Annual plan', NOW() - INTERVAL '40 days', NOW() - INTERVAL '40 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Udemy Business', 360.00, 'USD', CURRENT_DATE + INTERVAL '365 days', 'yearly', 30, '8080', 'Team plan', NOW() - INTERVAL '41 days', NOW() - INTERVAL '41 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Codecademy Pro', 19.99, 'USD', CURRENT_DATE + INTERVAL '200 days', 'monthly', 2, '9090', NULL, NOW() - INTERVAL '42 days', NOW() - INTERVAL '42 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Pluralsight', 29.00, 'USD', CURRENT_DATE + INTERVAL '210 days', 'monthly', 5, NULL, NULL, NOW() - INTERVAL '43 days', NOW() - INTERVAL '43 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Treehouse', 25.00, 'USD', CURRENT_DATE + INTERVAL '220 days', 'monthly', 7, '1111', NULL, NOW() - INTERVAL '44 days', NOW() - INTERVAL '44 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'New York Times', 17.00, 'USD', CURRENT_DATE + INTERVAL '230 days', 'monthly', 1, '2222', 'Digital subscription', NOW() - INTERVAL '45 days', NOW() - INTERVAL '45 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Wall Street Journal', 38.99, 'USD', CURRENT_DATE + INTERVAL '240 days', 'monthly', 3, '3333', NULL, NOW() - INTERVAL '46 days', NOW() - INTERVAL '46 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'The Economist', 22.00, 'USD', CURRENT_DATE + INTERVAL '250 days', 'monthly', 2, '4444', NULL, NOW() - INTERVAL '47 days', NOW() - INTERVAL '47 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Bloomberg', 34.99, 'USD', CURRENT_DATE + INTERVAL '260 days', 'monthly', 5, '5555', NULL, NOW() - INTERVAL '48 days', NOW() - INTERVAL '48 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Medium Member', 5.00, 'USD', CURRENT_DATE + INTERVAL '270 days', 'monthly', 0, '6666', NULL, NOW() - INTERVAL '49 days', NOW() - INTERVAL '49 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Patreon Creator', 10.00, 'USD', CURRENT_DATE + INTERVAL '280 days', 'monthly', 1, '7777', NULL, NOW() - INTERVAL '50 days', NOW() - INTERVAL '50 days');

-- ============================================
-- Summary:
-- ✅ Deleted all existing subscriptions for user_id: b067789d-3164-485c-8f09-8f1ba92c8d2c
-- ✅ Inserted 50 new subscription records:
--    - Orange Status (0-7 days): 8 subscriptions
--    - Green Status (>7 days): 42 subscriptions
-- ============================================
