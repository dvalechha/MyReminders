-- ============================================
-- Test Data: 50 Subscription Records
-- ============================================
-- This script inserts 50 test subscription records for UI testing
-- All records use the same user_id and category_id as specified
-- ============================================

-- Hard-coded values
-- user_id: b067789d-3164-485c-8f09-8f1ba92c8d2c
-- category_id: 2fdbd1b8-a492-44dd-97aa-23e995f41de8

INSERT INTO subscriptions (user_id, category_id, title, amount, currency, renewal_date, billing_cycle, reminder_days_before, payment_last4, notes, created_at, updated_at) VALUES
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Netflix', 15.99, 'USD', '2026-01-15', 'monthly', 3, '4242', 'Standard plan', NOW() - INTERVAL '30 days', NOW() - INTERVAL '30 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Spotify Premium', 9.99, 'USD', '2026-01-20', 'monthly', 1, '1234', NULL, NOW() - INTERVAL '25 days', NOW() - INTERVAL '25 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Adobe Creative Cloud', 52.99, 'USD', '2026-02-01', 'monthly', 7, '5678', 'Annual plan, billed monthly', NOW() - INTERVAL '20 days', NOW() - INTERVAL '20 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Amazon Prime', 14.99, 'USD', '2026-01-25', 'monthly', 5, '9012', NULL, NOW() - INTERVAL '15 days', NOW() - INTERVAL '15 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Microsoft 365', 6.99, 'USD', '2026-02-05', 'monthly', 2, '3456', 'Personal subscription', NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Disney+', 10.99, 'USD', '2026-01-18', 'monthly', 3, NULL, NULL, NOW() - INTERVAL '28 days', NOW() - INTERVAL '28 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Apple Music', 10.99, 'USD', '2026-01-22', 'monthly', 1, '7890', NULL, NOW() - INTERVAL '22 days', NOW() - INTERVAL '22 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'YouTube Premium', 13.99, 'USD', '2026-01-28', 'monthly', 2, '2468', NULL, NOW() - INTERVAL '18 days', NOW() - INTERVAL '18 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'HBO Max', 15.99, 'USD', '2026-02-10', 'monthly', 5, '1357', NULL, NOW() - INTERVAL '12 days', NOW() - INTERVAL '12 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Dropbox Plus', 9.99, 'USD', '2026-01-30', 'monthly', 3, '9876', '2TB storage', NOW() - INTERVAL '16 days', NOW() - INTERVAL '16 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'iCloud Storage', 0.99, 'USD', '2026-01-12', 'monthly', 0, NULL, '50GB plan', NOW() - INTERVAL '35 days', NOW() - INTERVAL '35 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'GitHub Pro', 4.00, 'USD', '2026-02-08', 'monthly', 1, '5432', NULL, NOW() - INTERVAL '8 days', NOW() - INTERVAL '8 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Notion Pro', 8.00, 'USD', '2026-01-26', 'monthly', 2, '1111', NULL, NOW() - INTERVAL '14 days', NOW() - INTERVAL '14 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Figma Professional', 12.00, 'USD', '2026-02-12', 'monthly', 7, '2222', NULL, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'LinkedIn Premium', 29.99, 'USD', '2026-02-15', 'monthly', 5, '3333', 'Career plan', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Audible', 14.95, 'USD', '2026-01-16', 'monthly', 1, '4444', NULL, NOW() - INTERVAL '32 days', NOW() - INTERVAL '32 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Hulu', 7.99, 'USD', '2026-01-24', 'monthly', 2, '5555', 'Basic plan', NOW() - INTERVAL '24 days', NOW() - INTERVAL '24 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Paramount+', 5.99, 'USD', '2026-02-03', 'monthly', 1, NULL, NULL, NOW() - INTERVAL '9 days', NOW() - INTERVAL '9 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Apple TV+', 6.99, 'USD', '2026-01-19', 'monthly', 3, '6666', NULL, NOW() - INTERVAL '27 days', NOW() - INTERVAL '27 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Shutterstock', 29.99, 'USD', '2026-02-20', 'monthly', 7, '7777', '10 images per month', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Canva Pro', 12.99, 'USD', '2026-01-27', 'monthly', 2, '8888', NULL, NOW() - INTERVAL '13 days', NOW() - INTERVAL '13 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Zoom Pro', 14.99, 'USD', '2026-02-07', 'monthly', 5, '9999', NULL, NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Slack Pro', 7.25, 'USD', '2026-01-21', 'monthly', 1, '0000', NULL, NOW() - INTERVAL '23 days', NOW() - INTERVAL '23 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Evernote Premium', 7.99, 'USD', '2026-02-09', 'monthly', 3, '1212', NULL, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Grammarly Premium', 12.00, 'USD', '2026-01-29', 'monthly', 2, '3434', NULL, NOW() - INTERVAL '17 days', NOW() - INTERVAL '17 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', '1Password', 2.99, 'USD', '2026-02-11', 'monthly', 1, '5656', 'Individual plan', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'LastPass Premium', 3.00, 'USD', '2026-01-14', 'monthly', 0, '7878', NULL, NOW() - INTERVAL '33 days', NOW() - INTERVAL '33 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'NordVPN', 11.95, 'USD', '2026-02-13', 'monthly', 5, '9090', NULL, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Surfshark', 12.95, 'USD', '2026-01-17', 'monthly', 3, NULL, NULL, NOW() - INTERVAL '31 days', NOW() - INTERVAL '31 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'ExpressVPN', 12.95, 'USD', '2026-02-06', 'monthly', 7, '2323', NULL, NOW() - INTERVAL '11 days', NOW() - INTERVAL '11 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Crunchyroll Premium', 7.99, 'USD', '2026-01-23', 'monthly', 2, '4545', NULL, NOW() - INTERVAL '21 days', NOW() - INTERVAL '21 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Twitch Turbo', 8.99, 'USD', '2026-02-14', 'monthly', 1, '6767', NULL, NOW() - INTERVAL '0 days', NOW() - INTERVAL '0 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Discord Nitro', 9.99, 'USD', '2026-01-31', 'monthly', 3, '8989', NULL, NOW() - INTERVAL '19 days', NOW() - INTERVAL '19 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Strava Premium', 5.00, 'USD', '2026-02-16', 'monthly', 5, NULL, NULL, NOW() - INTERVAL '29 days', NOW() - INTERVAL '29 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'MyFitnessPal Premium', 9.99, 'USD', '2026-01-13', 'monthly', 0, '1010', NULL, NOW() - INTERVAL '34 days', NOW() - INTERVAL '34 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Headspace', 12.99, 'USD', '2026-02-18', 'monthly', 7, '2020', NULL, NOW() - INTERVAL '26 days', NOW() - INTERVAL '26 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Calm Premium', 14.99, 'USD', '2026-01-11', 'monthly', 2, '3030', NULL, NOW() - INTERVAL '36 days', NOW() - INTERVAL '36 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Duolingo Plus', 6.99, 'USD', '2026-02-04', 'monthly', 1, '4040', NULL, NOW() - INTERVAL '37 days', NOW() - INTERVAL '37 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Babbel', 13.95, 'USD', '2026-01-10', 'monthly', 3, '5050', NULL, NOW() - INTERVAL '38 days', NOW() - INTERVAL '38 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'MasterClass', 15.00, 'USD', '2026-02-19', 'monthly', 5, '6060', NULL, NOW() - INTERVAL '39 days', NOW() - INTERVAL '39 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Skillshare', 32.00, 'USD', '2026-01-09', 'monthly', 7, '7070', 'Annual plan', NOW() - INTERVAL '40 days', NOW() - INTERVAL '40 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Udemy Business', 360.00, 'USD', '2026-03-01', 'yearly', 30, '8080', 'Team plan', NOW() - INTERVAL '41 days', NOW() - INTERVAL '41 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Codecademy Pro', 19.99, 'USD', '2026-02-02', 'monthly', 2, '9090', NULL, NOW() - INTERVAL '42 days', NOW() - INTERVAL '42 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Pluralsight', 29.00, 'USD', '2026-01-08', 'monthly', 5, NULL, NULL, NOW() - INTERVAL '43 days', NOW() - INTERVAL '43 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Treehouse', 25.00, 'USD', '2026-02-17', 'monthly', 7, '1111', NULL, NOW() - INTERVAL '44 days', NOW() - INTERVAL '44 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'New York Times', 17.00, 'USD', '2026-01-07', 'monthly', 1, '2222', 'Digital subscription', NOW() - INTERVAL '45 days', NOW() - INTERVAL '45 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Wall Street Journal', 38.99, 'USD', '2026-02-21', 'monthly', 3, '3333', NULL, NOW() - INTERVAL '46 days', NOW() - INTERVAL '46 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'The Economist', 22.00, 'USD', '2026-01-06', 'monthly', 2, '4444', NULL, NOW() - INTERVAL '47 days', NOW() - INTERVAL '47 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Bloomberg', 34.99, 'USD', '2026-02-22', 'monthly', 5, '5555', NULL, NOW() - INTERVAL '48 days', NOW() - INTERVAL '48 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Medium Member', 5.00, 'USD', '2026-01-05', 'monthly', 0, '6666', NULL, NOW() - INTERVAL '49 days', NOW() - INTERVAL '49 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Patreon Creator', 10.00, 'USD', '2026-02-23', 'monthly', 1, '7777', NULL, NOW() - INTERVAL '50 days', NOW() - INTERVAL '50 days');

-- ============================================
-- Summary: 50 subscription records inserted
-- All records use:
--   user_id: b067789d-3164-485c-8f09-8f1ba92c8d2c
--   category_id: 2fdbd1b8-a492-44dd-97aa-23e995f41de8
-- ============================================

