-- =============================================================================
-- File: sql/02_seed_data.sql
-- Database: service_repair_db (PostgreSQL 18)
-- Description: Sample seed data for all 8 tables in parent-to-child order.
--              Uses explicit transactions (BEGIN / COMMIT) and omits identity
--              columns so PostgreSQL generates primary keys automatically.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1. service_categories (6 rows)
-- -----------------------------------------------------------------------------
INSERT INTO service_categories (category_name, description, is_active) VALUES
    ('HVAC & Cooling', 'Air conditioning, ventilation, and climate control repairs.', TRUE),
    ('Electrical Systems', 'Circuit panels, outlets, lighting, and residential wiring.', TRUE),
    ('Plumbing & Water', 'Leak detection, pipe repairs, and water heater servicing.', TRUE),
    ('Home Appliances', 'Diagnostics and repairs for washers, dryers, and kitchen units.', TRUE),
    ('Smart Home & Security', 'Smart locks, thermostats, cameras, and automation setup.', TRUE),
    ('Seasonal Heating', 'Annual furnace safety inspections and legacy heater support.', FALSE);

-- -----------------------------------------------------------------------------
-- 2. customers (8 rows across 5 cities)
-- -----------------------------------------------------------------------------
INSERT INTO customers (full_name, phone, email, city, created_at) VALUES
    ('Daniel Harper', '+1-206-555-0141', 'daniel.harper@example.com', 'Seattle', '2026-08-12 09:30:00+00'),
    ('Emily Foster', '+1-512-555-0182', 'emily.foster@example.com', 'Austin', '2026-08-19 14:15:00+00'),
    ('Michael Turner', '+1-303-555-0123', 'michael.turner@example.com', 'Denver', '2026-09-02 11:00:00+00'),
    ('Hannah Collins', '+1-206-555-0164', 'hannah.collins@example.com', 'Seattle', '2026-09-10 16:45:00+00'),
    ('Jacob Simmons', '+1-312-555-0195', 'jacob.simmons@example.com', 'Chicago', '2026-09-18 10:20:00+00'),
    ('Claire Morgan', '+1-512-555-0136', 'claire.morgan@example.com', 'Austin', '2026-09-27 13:50:00+00'),
    ('Lucas Hayes', '+1-617-555-0177', 'lucas.hayes@example.com', 'Boston', '2026-10-04 08:40:00+00'),
    ('Natalie Ward', '+1-303-555-0158', 'natalie.ward@example.com', 'Denver', '2026-10-11 17:10:00+00');

-- -----------------------------------------------------------------------------
-- 3. technicians (6 rows; includes 1 inactive technician and hire_date)
-- -----------------------------------------------------------------------------
INSERT INTO technicians (full_name, specialty, phone, hourly_rate, is_active, hire_date) VALUES
    ('Liam Carter', 'HVAC & Refrigeration', '+1-206-555-0201', 75.00, TRUE, '2021-03-15'),
    ('Sophia Bennett', 'Electrical Systems', '+1-512-555-0202', 80.00, TRUE, '2022-06-01'),
    ('Noah Martinez', 'Plumbing & Pipefitting', '+1-303-555-0203', 70.00, TRUE, '2022-11-10'),
    ('Olivia Brooks', 'Appliance Diagnostics', '+1-312-555-0204', 65.00, TRUE, '2023-04-20'),
    ('Ethan Wright', 'Smart Home & Controls', '+1-617-555-0205', 85.00, TRUE, '2024-02-05'),
    ('Mason Reed', 'General Heating & Ducts', '+1-303-555-0206', 68.00, FALSE, '2020-09-12');

-- -----------------------------------------------------------------------------
-- 4. services (9 rows across all 6 categories)
-- -----------------------------------------------------------------------------
INSERT INTO services (category_id, service_name, base_price, estimated_minutes) VALUES
    (1, 'AC Compressor Tune-Up', 140.00, 90),
    (1, 'Thermostat Calibration', 75.00, 45),
    (2, 'Circuit Breaker Replacement', 160.00, 75),
    (2, 'Outlet & Wiring Inspection', 90.00, 60),
    (3, 'Pipe Leak Detection & Sealing', 120.00, 80),
    (3, 'Water Heater Flush & Check', 110.00, 65),
    (4, 'Washing Machine Drain Repair', 130.00, 70),
    (5, 'Smart Lock & Camera Setup', 150.00, 90),
    (6, 'Furnace Annual Safety Check', 125.00, 75);

-- -----------------------------------------------------------------------------
-- 5. requests (9 rows: 6 COMPLETED, 1 IN_PROGRESS, 1 PENDING with NULL tech, 1 CANCELLED)
-- -----------------------------------------------------------------------------
INSERT INTO requests (customer_id, technician_id, request_date, status, address) VALUES
    (1, 1, '2026-10-02 10:15:00+00', 'COMPLETED', '742 Pine St, Apt 4B, Seattle, WA'),
    (2, 2, '2026-10-05 14:30:00+00', 'COMPLETED', '1204 Congress Ave, Austin, TX'),
    (3, 3, '2026-10-09 09:00:00+00', 'COMPLETED', '885 Blake St, Suite 2, Denver, CO'),
    (4, 4, '2026-10-14 16:45:00+00', 'COMPLETED', '310 Mercer St, Seattle, WA'),
    (1, 5, '2026-10-19 11:20:00+00', 'COMPLETED', '742 Pine St, Apt 4B, Seattle, WA'),
    (5, 1, '2026-10-25 13:10:00+00', 'COMPLETED', '450 N Michigan Ave, Chicago, IL'),
    (6, 2, '2026-11-10 08:45:00+00', 'IN_PROGRESS', '2901 Barton Springs Rd, Austin, TX'),
    (7, NULL, '2026-11-18 15:00:00+00', 'PENDING', '118 Newbury St, Boston, MA'),
    (8, 4, '2026-11-02 12:00:00+00', 'CANCELLED', '1620 Wynkoop St, Denver, CO');

-- -----------------------------------------------------------------------------
-- 6. request_items (13 rows; unit_price matches services.base_price)
-- -----------------------------------------------------------------------------
INSERT INTO request_items (request_id, service_id, quantity, unit_price) VALUES
    (1, 1, 1, 140.00),
    (1, 2, 1, 75.00),
    (2, 3, 1, 160.00),
    (2, 4, 2, 90.00),
    (3, 5, 1, 120.00),
    (3, 6, 1, 110.00),
    (4, 7, 1, 130.00),
    (5, 8, 2, 150.00),
    (6, 9, 1, 125.00),
    (6, 2, 1, 75.00),
    (7, 3, 1, 160.00),
    (8, 5, 1, 120.00),
    (9, 7, 1, 130.00);

-- -----------------------------------------------------------------------------
-- 7. payments (8 rows: 6 PAID matching COMPLETED totals, 1 FAILED, 1 REFUNDED)
-- -----------------------------------------------------------------------------
INSERT INTO payments (request_id, amount, payment_method, payment_status, paid_at) VALUES
    (1, 215.00, 'CARD', 'PAID', '2026-10-02 12:30:00+00'),
    (2, 340.00, 'ONLINE', 'PAID', '2026-10-05 17:00:00+00'),
    (3, 230.00, 'CASH', 'PAID', '2026-10-09 11:30:00+00'),
    (4, 130.00, 'CARD', 'PAID', '2026-10-14 18:15:00+00'),
    (5, 300.00, 'ONLINE', 'PAID', '2026-10-19 14:10:00+00'),
    (6, 200.00, 'CARD', 'PAID', '2026-10-25 15:40:00+00'),
    (7, 160.00, 'ONLINE', 'FAILED', '2026-11-10 09:05:00+00'),
    (9, 130.00, 'CARD', 'REFUNDED', '2026-11-02 14:00:00+00');

-- -----------------------------------------------------------------------------
-- 8. reviews (6 rows; strictly for COMPLETED requests 1..6)
-- -----------------------------------------------------------------------------
INSERT INTO reviews (request_id, rating, comment, created_at) VALUES
    (1, 5, 'Liam arrived on time and had our AC running smoothly within an hour.', '2026-10-03 09:00:00+00'),
    (2, 4, 'Clean electrical work and clear explanation, though traffic caused a slight delay.', '2026-10-06 10:15:00+00'),
    (3, 5, 'Quickly located the hidden pipe leak under the sink and sealed it cleanly.', '2026-10-10 08:30:00+00'),
    (4, 3, 'Drain issue was fixed properly, but cleanup around the washer could be better.', '2026-10-15 11:45:00+00'),
    (5, 5, 'Smart locks and cameras were configured flawlessly with a full app walkthrough.', '2026-10-20 16:00:00+00'),
    (6, 4, 'Thorough furnace safety check and thermostat calibration ahead of winter.', '2026-10-26 12:20:00+00');

COMMIT;

-- =============================================================================
-- Verification Query: Ensure every table has at least 6 rows (requests >= 8)
-- =============================================================================
SELECT 'service_categories' AS table_name, COUNT(*) AS row_count FROM service_categories
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'technicians', COUNT(*) FROM technicians
UNION ALL
SELECT 'services', COUNT(*) FROM services
UNION ALL
SELECT 'requests', COUNT(*) FROM requests
UNION ALL
SELECT 'request_items', COUNT(*) FROM request_items
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'reviews', COUNT(*) FROM reviews;
