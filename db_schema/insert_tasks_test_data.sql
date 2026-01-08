-- ============================================
-- Test Data: 50 Task Records
-- ============================================
-- This script inserts 50 test task records for UI testing
-- All records use the same user_id and category_id as specified
-- ============================================

-- Hard-coded values
-- user_id: b067789d-3164-485c-8f09-8f1ba92c8d2c
-- category_id: 2fdbd1b8-a492-44dd-97aa-23e995f41de8

INSERT INTO tasks (user_id, category_id, title, due_date, priority, notes, reminder_offset_minutes, created_at, updated_at) VALUES
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Complete project proposal', '2026-01-15 17:00:00+00', 'high', 'Need to submit by end of day', 60, NOW() - INTERVAL '30 days', NOW() - INTERVAL '30 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Review code changes', '2026-01-16 12:00:00+00', 'medium', 'PR #1234 needs review', 30, NOW() - INTERVAL '29 days', NOW() - INTERVAL '29 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Update documentation', '2026-01-17 18:00:00+00', 'low', 'API documentation needs refresh', 0, NOW() - INTERVAL '28 days', NOW() - INTERVAL '28 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Fix bug in login flow', '2026-01-18 14:00:00+00', 'high', 'Critical issue reported by QA', 60, NOW() - INTERVAL '27 days', NOW() - INTERVAL '27 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Write unit tests', '2026-01-19 16:00:00+00', 'medium', 'Coverage below 80%', 30, NOW() - INTERVAL '26 days', NOW() - INTERVAL '26 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Prepare presentation slides', '2026-01-20 10:00:00+00', 'high', 'Client presentation on Friday', 120, NOW() - INTERVAL '25 days', NOW() - INTERVAL '25 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Update dependencies', '2026-01-21 11:00:00+00', 'low', 'Security patches available', 0, NOW() - INTERVAL '24 days', NOW() - INTERVAL '24 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Design new feature mockup', '2026-01-22 15:00:00+00', 'medium', 'User dashboard redesign', 15, NOW() - INTERVAL '23 days', NOW() - INTERVAL '23 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Submit expense report', '2026-01-23 09:00:00+00', 'high', 'Monthly expenses due', 60, NOW() - INTERVAL '22 days', NOW() - INTERVAL '22 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Refactor authentication module', '2026-01-24 17:00:00+00', 'medium', 'Code quality improvement', 30, NOW() - INTERVAL '21 days', NOW() - INTERVAL '21 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Schedule team meeting', '2026-01-25 13:00:00+00', 'low', NULL, 0, NOW() - INTERVAL '20 days', NOW() - INTERVAL '20 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Backup database', '2026-01-26 02:00:00+00', 'high', 'Automated backup verification', 0, NOW() - INTERVAL '19 days', NOW() - INTERVAL '19 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Learn new framework', '2026-01-27 20:00:00+00', 'low', 'React 19 new features', 0, NOW() - INTERVAL '18 days', NOW() - INTERVAL '18 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Optimize database queries', '2026-01-28 14:00:00+00', 'medium', 'Performance improvements needed', 30, NOW() - INTERVAL '17 days', NOW() - INTERVAL '17 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Create user guide', '2026-01-29 11:00:00+00', 'medium', 'Product documentation', 15, NOW() - INTERVAL '16 days', NOW() - INTERVAL '16 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Deploy to staging', '2026-01-30 16:00:00+00', 'high', 'Test new release candidate', 60, NOW() - INTERVAL '15 days', NOW() - INTERVAL '15 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Update resume', '2026-01-31 18:00:00+00', 'low', 'Add recent projects', 0, NOW() - INTERVAL '14 days', NOW() - INTERVAL '14 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Setup CI/CD pipeline', '2026-02-01 10:00:00+00', 'high', 'Automated deployment needed', 30, NOW() - INTERVAL '13 days', NOW() - INTERVAL '13 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Review analytics data', '2026-02-02 15:00:00+00', 'medium', 'Monthly metrics analysis', 15, NOW() - INTERVAL '12 days', NOW() - INTERVAL '12 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Clean up old code', '2026-02-03 12:00:00+00', 'low', 'Remove deprecated functions', 0, NOW() - INTERVAL '11 days', NOW() - INTERVAL '11 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Implement new API endpoint', '2026-02-04 14:00:00+00', 'high', 'User management API', 60, NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Write blog post', '2026-02-05 17:00:00+00', 'low', 'Tech blog contribution', 0, NOW() - INTERVAL '9 days', NOW() - INTERVAL '9 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Fix security vulnerability', '2026-02-06 09:00:00+00', 'high', 'Critical security patch', 120, NOW() - INTERVAL '8 days', NOW() - INTERVAL '8 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Organize code review session', '2026-02-07 13:00:00+00', 'medium', 'Team code review', 15, NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Update website content', '2026-02-08 11:00:00+00', 'low', 'Homepage refresh', 0, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Configure monitoring tools', '2026-02-09 10:00:00+00', 'medium', 'Set up error tracking', 30, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Prepare quarterly report', '2026-02-10 16:00:00+00', 'high', 'Q4 performance summary', 60, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Study algorithm patterns', '2026-02-11 20:00:00+00', 'low', 'Dynamic programming review', 0, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Implement caching layer', '2026-02-12 15:00:00+00', 'medium', 'Improve API response times', 30, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Setup development environment', '2026-02-13 09:00:00+00', 'low', 'New team member onboarding', 0, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Review pull requests', '2026-02-14 14:00:00+00', 'medium', 'Multiple PRs pending', 15, NOW() - INTERVAL '0 days', NOW() - INTERVAL '0 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Create feature branch', '2026-02-15 10:00:00+00', 'low', 'New feature development', 0, NOW() - INTERVAL '35 days', NOW() - INTERVAL '35 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Update test cases', '2026-02-16 13:00:00+00', 'medium', 'Cover new edge cases', 30, NOW() - INTERVAL '36 days', NOW() - INTERVAL '36 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Migrate legacy code', '2026-02-17 11:00:00+00', 'high', 'Refactor old modules', 60, NOW() - INTERVAL '37 days', NOW() - INTERVAL '37 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Configure load balancer', '2026-02-18 10:00:00+00', 'medium', 'Production setup', 30, NOW() - INTERVAL '38 days', NOW() - INTERVAL '38 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Write technical documentation', '2026-02-19 16:00:00+00', 'low', 'Architecture overview', 0, NOW() - INTERVAL '39 days', NOW() - INTERVAL '39 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Fix memory leak', '2026-02-20 09:00:00+00', 'high', 'Production issue', 120, NOW() - INTERVAL '40 days', NOW() - INTERVAL '40 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Setup error logging', '2026-02-21 12:00:00+00', 'medium', 'Centralized error tracking', 15, NOW() - INTERVAL '41 days', NOW() - INTERVAL '41 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Optimize images', '2026-02-22 14:00:00+00', 'low', 'Reduce page load time', 0, NOW() - INTERVAL '42 days', NOW() - INTERVAL '42 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Implement authentication', '2026-02-23 11:00:00+00', 'high', 'OAuth integration', 60, NOW() - INTERVAL '43 days', NOW() - INTERVAL '43 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Update dependencies list', '2026-02-24 15:00:00+00', 'low', 'Check for outdated packages', 0, NOW() - INTERVAL '44 days', NOW() - INTERVAL '44 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Configure SSL certificate', '2026-02-25 10:00:00+00', 'high', 'Security requirement', 60, NOW() - INTERVAL '45 days', NOW() - INTERVAL '45 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Write release notes', '2026-02-26 13:00:00+00', 'medium', 'Version 2.0 changelog', 15, NOW() - INTERVAL '46 days', NOW() - INTERVAL '46 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Setup automated testing', '2026-02-27 09:00:00+00', 'medium', 'Integration test suite', 30, NOW() - INTERVAL '47 days', NOW() - INTERVAL '47 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Refactor data models', '2026-02-28 16:00:00+00', 'low', 'Code organization', 0, NOW() - INTERVAL '48 days', NOW() - INTERVAL '48 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Deploy hotfix', '2026-03-01 08:00:00+00', 'high', 'Urgent production fix', 120, NOW() - INTERVAL '49 days', NOW() - INTERVAL '49 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '2fdbd1b8-a492-44dd-97aa-23e995f41de8', 'Update API documentation', '2026-03-02 12:00:00+00', 'medium', 'Swagger docs refresh', 15, NOW() - INTERVAL '50 days', NOW() - INTERVAL '50 days');

-- ============================================
-- Summary: 50 task records inserted
-- All records use:
--   user_id: b067789d-3164-485c-8f09-8f1ba92c8d2c
--   category_id: 2fdbd1b8-a492-44dd-97aa-23e995f41de8
-- ============================================
