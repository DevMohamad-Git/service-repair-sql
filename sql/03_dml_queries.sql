-- =============================================================================
-- File: sql/03_dml_queries.sql
-- Database: service_repair_db (PostgreSQL 18)
-- Description: Analytical SELECT queries (WHERE, ORDER BY, JOIN, LEFT JOIN,
--              GROUP BY, HAVING, Subquery) followed by safe transactional
--              UPDATE and DELETE operations.
--              All read-only queries run first on clean seed data.
-- =============================================================================

-- =============================================================================
-- PART 1: READ-ONLY ANALYTICAL QUERIES (SELECT)
-- =============================================================================

-- 1. Simple SELECT with WHERE and ORDER BY
-- Purpose: List all active technicians sorted by hourly rate from lowest to highest.
SELECT
    technician_id,
    full_name,
    specialty,
    hourly_rate,
    hire_date
FROM technicians
WHERE is_active = TRUE
ORDER BY hourly_rate ASC, full_name ASC;

-- 2. Multi-table INNER JOIN
-- Purpose: Display completed request details including customer, technician, service item, and total paid amount.
SELECT
    r.request_id,
    c.full_name AS customer_name,
    t.full_name AS technician_name,
    s.service_name,
    ri.quantity,
    (ri.quantity * ri.unit_price) AS line_total,
    p.amount AS total_paid_amount
FROM requests r
INNER JOIN customers c ON c.customer_id = r.customer_id
INNER JOIN technicians t ON t.technician_id = r.technician_id
INNER JOIN request_items ri ON ri.request_id = r.request_id
INNER JOIN services s ON s.service_id = ri.service_id
INNER JOIN payments p ON p.request_id = r.request_id
WHERE r.status = 'COMPLETED'
  AND p.payment_status = 'PAID'
ORDER BY r.request_id ASC, ri.item_id ASC;

-- 3a. LEFT JOIN (Unassigned requests)
-- Purpose: Find service requests that do not have an assigned technician yet (PENDING orders).
SELECT
    r.request_id,
    c.full_name AS customer_name,
    r.request_date,
    r.status,
    r.address
FROM requests r
INNER JOIN customers c ON c.customer_id = r.customer_id
LEFT JOIN technicians t ON t.technician_id = r.technician_id
WHERE t.technician_id IS NULL
ORDER BY r.request_date ASC;

-- 3b. LEFT JOIN (Technicians without assigned requests)
-- Purpose: Identify technicians who currently have no assigned service requests.
SELECT
    t.technician_id,
    t.full_name AS technician_name,
    t.specialty,
    t.is_active
FROM technicians t
LEFT JOIN requests r ON r.technician_id = t.technician_id
WHERE r.request_id IS NULL
ORDER BY t.technician_id ASC;

-- 4a. GROUP BY with SUM and COUNT (Revenue per service category)
-- Purpose: Calculate total completed service revenue and item count for each service category.
SELECT
    sc.category_id,
    sc.category_name,
    COUNT(ri.item_id) AS completed_item_count,
    COALESCE(SUM(ri.quantity * ri.unit_price), 0.00) AS total_revenue
FROM service_categories sc
LEFT JOIN services s ON s.category_id = sc.category_id
LEFT JOIN request_items ri ON ri.service_id = s.service_id
LEFT JOIN requests r ON r.request_id = ri.request_id AND r.status = 'COMPLETED'
GROUP BY sc.category_id, sc.category_name
ORDER BY total_revenue DESC, sc.category_name ASC;

-- 4b. GROUP BY with AVG and COUNT (Average rating per technician)
-- Purpose: Compute the average customer rating and total review count for each reviewed technician.
SELECT
    t.technician_id,
    t.full_name AS technician_name,
    COUNT(rv.review_id) AS review_count,
    ROUND(AVG(rv.rating), 2) AS avg_rating
FROM technicians t
INNER JOIN requests r ON r.technician_id = t.technician_id
INNER JOIN reviews rv ON rv.request_id = r.request_id
GROUP BY t.technician_id, t.full_name
ORDER BY avg_rating DESC, review_count DESC, t.full_name ASC;

-- 4c. GROUP BY with COUNT (Request count per customer)
-- Purpose: Count total service requests submitted by each customer.
SELECT
    c.customer_id,
    c.full_name AS customer_name,
    c.city,
    COUNT(r.request_id) AS total_requests
FROM customers c
LEFT JOIN requests r ON r.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name, c.city
ORDER BY total_requests DESC, c.full_name ASC;

-- 5. GROUP BY with HAVING
-- Purpose: List technicians whose average review rating is strictly higher than 4.0.
SELECT
    t.technician_id,
    t.full_name AS technician_name,
    COUNT(rv.review_id) AS review_count,
    ROUND(AVG(rv.rating), 2) AS avg_rating
FROM technicians t
INNER JOIN requests r ON r.technician_id = t.technician_id
INNER JOIN reviews rv ON rv.request_id = r.request_id
GROUP BY t.technician_id, t.full_name
HAVING AVG(rv.rating) > 4
ORDER BY avg_rating DESC, t.full_name ASC;

-- 6. Subquery
-- Purpose: Find customers whose total request count exceeds the average request count across all customers.
SELECT
    c.customer_id,
    c.full_name AS customer_name,
    c.city,
    COUNT(r.request_id) AS request_count
FROM customers c
LEFT JOIN requests r ON r.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name, c.city
HAVING COUNT(r.request_id) > (
    SELECT AVG(customer_req_count)
    FROM (
        SELECT COUNT(r2.request_id) AS customer_req_count
        FROM customers c2
        LEFT JOIN requests r2 ON r2.customer_id = c2.customer_id
        GROUP BY c2.customer_id
    ) AS customer_totals
)
ORDER BY request_count DESC, c.full_name ASC;


-- =============================================================================
-- PART 2: SAFE TRANSACTIONAL UPDATES AND DELETES
-- =============================================================================

-- 7a. Safe UPDATE #1: Assign an active technician to a PENDING request
-- Purpose: Preview the target PENDING request before updating its status and technician assignment.
SELECT
    request_id,
    customer_id,
    technician_id,
    status,
    address
FROM requests
WHERE request_id = 8
  AND status = 'PENDING';

BEGIN;

-- Purpose: Assign active technician #3 (Noah Martinez) to PENDING request #8 and update status to ASSIGNED.
UPDATE requests
SET
    status = 'ASSIGNED',
    technician_id = 3
WHERE request_id = 8
  AND status = 'PENDING';

COMMIT;

-- Purpose: Verify the updated request status and assigned technician after COMMIT.
SELECT
    request_id,
    customer_id,
    technician_id,
    status,
    address
FROM requests
WHERE request_id = 8;

-- 7b. Safe UPDATE #2: Increase base_price of a specific service by 10%
-- Purpose: Inspect the current base price of 'Thermostat Calibration' before applying the 10% increase.
SELECT
    service_id,
    service_name,
    base_price
FROM services
WHERE service_name = 'Thermostat Calibration';

BEGIN;

-- Purpose: Increase the base price of 'Thermostat Calibration' by 10 percent.
UPDATE services
SET base_price = ROUND(base_price * 1.10, 2)
WHERE service_name = 'Thermostat Calibration';

COMMIT;

-- Purpose: Verify the updated base price of 'Thermostat Calibration' after COMMIT.
SELECT
    service_id,
    service_name,
    base_price
FROM services
WHERE service_name = 'Thermostat Calibration';

-- 8. Safe conditional DELETE (insert isolated test customer, verify, delete, and verify removal)
BEGIN;

-- Purpose: Insert a temporary test customer with no dependent requests for safe DELETE demonstration.
INSERT INTO customers (full_name, phone, email, city)
VALUES ('Temp Test Customer', '+1-503-555-0199', 'temp.delete.demo@example.com', 'Portland');

-- Purpose: Confirm the test customer exists before deleting it.
SELECT
    customer_id,
    full_name,
    phone,
    email,
    city
FROM customers
WHERE email = 'temp.delete.demo@example.com';

-- Purpose: Safely remove only the isolated test customer using an exact WHERE filter.
DELETE FROM customers
WHERE email = 'temp.delete.demo@example.com';

-- Purpose: Verify that the test customer has been completely removed (expected 0 rows).
SELECT
    customer_id,
    full_name,
    phone,
    email,
    city
FROM customers
WHERE email = 'temp.delete.demo@example.com';

COMMIT;
