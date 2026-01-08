-- ============================================
-- Test Data: 50 Appointment Records
-- ============================================
-- This script inserts 50 test appointment records for UI testing
-- All records use the same user_id and category_id as specified
-- ============================================

-- Hard-coded values
-- user_id: b067789d-3164-485c-8f09-8f1ba92c8d2c
-- category_id: 30ac390b-ae19-460c-9f49-36755112a31e

INSERT INTO appointments (user_id, category_id, title, start_time, location, notes, reminder_offset_minutes, created_at, updated_at) VALUES
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Team Standup Meeting', '2026-01-15 09:00:00+00', 'Conference Room A', 'Weekly team sync', 15, NOW() - INTERVAL '30 days', NOW() - INTERVAL '30 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Client Presentation', '2026-01-16 14:30:00+00', 'Virtual - Zoom', 'Q4 results presentation', 30, NOW() - INTERVAL '29 days', NOW() - INTERVAL '29 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Dentist Appointment', '2026-01-17 10:00:00+00', '123 Main St, Suite 200', 'Regular cleaning', 60, NOW() - INTERVAL '28 days', NOW() - INTERVAL '28 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Project Review', '2026-01-18 11:00:00+00', 'Office - Building B', 'Review project milestones', 15, NOW() - INTERVAL '27 days', NOW() - INTERVAL '27 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Lunch with Sarah', '2026-01-19 12:30:00+00', 'The Corner Cafe', 'Discuss partnership opportunity', 0, NOW() - INTERVAL '26 days', NOW() - INTERVAL '26 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Job Interview', '2026-01-20 15:00:00+00', 'Virtual - Microsoft Teams', 'Senior Developer position', 60, NOW() - INTERVAL '25 days', NOW() - INTERVAL '25 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Gym Session', '2026-01-21 07:00:00+00', 'FitZone Gym', 'Morning workout', 0, NOW() - INTERVAL '24 days', NOW() - INTERVAL '24 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Code Review Session', '2026-01-22 16:00:00+00', 'Virtual - Slack', 'Review PR #1234', 30, NOW() - INTERVAL '23 days', NOW() - INTERVAL '23 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Doctor Checkup', '2026-01-23 09:30:00+00', 'Health Center, Floor 3', 'Annual physical', 120, NOW() - INTERVAL '22 days', NOW() - INTERVAL '22 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Team Building Event', '2026-01-24 17:00:00+00', 'City Park', 'Outdoor activities', 0, NOW() - INTERVAL '21 days', NOW() - INTERVAL '21 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Budget Planning Meeting', '2026-01-25 13:00:00+00', 'Conference Room B', 'Q1 budget review', 15, NOW() - INTERVAL '20 days', NOW() - INTERVAL '20 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Coffee with Mentor', '2026-01-26 08:00:00+00', 'Starbucks Downtown', 'Career discussion', 0, NOW() - INTERVAL '19 days', NOW() - INTERVAL '19 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Sprint Planning', '2026-01-27 10:00:00+00', 'Virtual - Google Meet', 'Plan next sprint', 15, NOW() - INTERVAL '18 days', NOW() - INTERVAL '18 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Veterinary Visit', '2026-01-28 14:00:00+00', 'PetCare Clinic', 'Routine checkup for Max', 30, NOW() - INTERVAL '17 days', NOW() - INTERVAL '17 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Training Workshop', '2026-01-29 09:00:00+00', 'Training Center', 'Advanced React patterns', 60, NOW() - INTERVAL '16 days', NOW() - INTERVAL '16 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Networking Event', '2026-01-30 18:00:00+00', 'Tech Hub Co-working', 'Industry meetup', 0, NOW() - INTERVAL '15 days', NOW() - INTERVAL '15 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Parent-Teacher Conference', '2026-01-31 15:30:00+00', 'Elementary School', 'Discuss progress report', 60, NOW() - INTERVAL '14 days', NOW() - INTERVAL '14 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Product Demo', '2026-02-01 11:00:00+00', 'Virtual - Zoom', 'Demo new features to stakeholders', 30, NOW() - INTERVAL '13 days', NOW() - INTERVAL '13 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Yoga Class', '2026-02-02 18:30:00+00', 'Zen Studio', 'Evening relaxation', 0, NOW() - INTERVAL '12 days', NOW() - INTERVAL '12 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Performance Review', '2026-02-03 14:00:00+00', 'Manager Office', 'Annual review discussion', 15, NOW() - INTERVAL '11 days', NOW() - INTERVAL '11 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Car Maintenance', '2026-02-04 08:00:00+00', 'Auto Service Center', 'Oil change and inspection', 120, NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Haircut Appointment', '2026-02-05 12:00:00+00', 'Barber Shop Central', NULL, 0, NOW() - INTERVAL '9 days', NOW() - INTERVAL '9 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Board Meeting', '2026-02-06 16:00:00+00', 'Executive Conference Room', 'Quarterly board review', 30, NOW() - INTERVAL '8 days', NOW() - INTERVAL '8 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Cooking Class', '2026-02-07 19:00:00+00', 'Culinary Academy', 'Italian cuisine basics', 0, NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Architect Review', '2026-02-08 10:30:00+00', 'Design Studio', 'Home renovation plans', 60, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Security Training', '2026-02-09 13:00:00+00', 'Virtual - WebEx', 'Cybersecurity best practices', 15, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Bank Appointment', '2026-02-10 09:00:00+00', 'Main Branch', 'Mortgage consultation', 60, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Music Concert', '2026-02-11 20:00:00+00', 'Concert Hall', 'Jazz night', 0, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Client Call', '2026-02-12 11:30:00+00', 'Virtual - Phone', 'Discuss project requirements', 15, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Retrospective Meeting', '2026-02-13 15:00:00+00', 'Virtual - Miro', 'Sprint retrospective', 15, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Birthday Party', '2026-02-14 17:00:00+00', 'Friend House', 'Sarah birthday celebration', 0, NOW() - INTERVAL '0 days', NOW() - INTERVAL '0 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Architecture Review', '2026-02-15 14:00:00+00', 'Virtual - Figma', 'System design discussion', 30, NOW() - INTERVAL '35 days', NOW() - INTERVAL '35 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Swimming Lesson', '2026-02-16 07:30:00+00', 'Community Pool', 'Weekly swimming class', 0, NOW() - INTERVAL '36 days', NOW() - INTERVAL '36 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Investment Consultation', '2026-02-17 10:00:00+00', 'Financial Advisor Office', 'Portfolio review', 60, NOW() - INTERVAL '37 days', NOW() - INTERVAL '37 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Movie Night', '2026-02-18 19:30:00+00', 'Cinema Complex', 'New action movie premiere', 0, NOW() - INTERVAL '38 days', NOW() - INTERVAL '38 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Technical Interview', '2026-02-19 15:30:00+00', 'Virtual - CoderPad', 'Coding challenge session', 30, NOW() - INTERVAL '39 days', NOW() - INTERVAL '39 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Marathon Training', '2026-02-20 06:00:00+00', 'City Trail', 'Long distance run', 0, NOW() - INTERVAL '40 days', NOW() - INTERVAL '40 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Legal Consultation', '2026-02-21 13:30:00+00', 'Law Firm Office', 'Contract review', 60, NOW() - INTERVAL '41 days', NOW() - INTERVAL '41 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Art Gallery Opening', '2026-02-22 18:00:00+00', 'Modern Art Gallery', 'New exhibition preview', 0, NOW() - INTERVAL '42 days', NOW() - INTERVAL '42 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Design Critique', '2026-02-23 11:00:00+00', 'Virtual - Figma', 'UI/UX design review', 15, NOW() - INTERVAL '43 days', NOW() - INTERVAL '43 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Weekend Hike', '2026-02-24 08:00:00+00', 'Mountain Trail', 'Nature exploration', 0, NOW() - INTERVAL '44 days', NOW() - INTERVAL '44 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Sales Pitch', '2026-02-25 14:00:00+00', 'Client Office', 'Present new product line', 30, NOW() - INTERVAL '45 days', NOW() - INTERVAL '45 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Photography Workshop', '2026-02-26 10:00:00+00', 'Photo Studio', 'Landscape photography techniques', 15, NOW() - INTERVAL '46 days', NOW() - INTERVAL '46 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Wedding Planning', '2026-02-27 16:00:00+00', 'Event Venue', 'Venue tour and discussion', 60, NOW() - INTERVAL '47 days', NOW() - INTERVAL '47 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Language Class', '2026-02-28 18:30:00+00', 'Language School', 'Spanish intermediate', 0, NOW() - INTERVAL '48 days', NOW() - INTERVAL '48 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Real Estate Viewing', '2026-03-01 11:00:00+00', 'Apartment Complex', '2-bedroom apartment tour', 30, NOW() - INTERVAL '49 days', NOW() - INTERVAL '49 days'),
('b067789d-3164-485c-8f09-8f1ba92c8d2c', '30ac390b-ae19-460c-9f49-36755112a31e', 'Conference Keynote', '2026-03-02 09:00:00+00', 'Convention Center', 'Tech industry trends', 60, NOW() - INTERVAL '50 days', NOW() - INTERVAL '50 days');

-- ============================================
-- Summary: 50 appointment records inserted
-- All records use:
--   user_id: b067789d-3164-485c-8f09-8f1ba92c8d2c
--   category_id: 30ac390b-ae19-460c-9f49-36755112a31e
-- ============================================
