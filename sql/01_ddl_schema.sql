-- =============================================================================
-- File: sql/01_ddl_schema.sql
-- Database: service_repair_db (PostgreSQL 18)
-- Description: DDL schema definition for the Service & Repair Management System.
--              Creates 8 tables in parent-to-child order with explicit constraints,
--              foreign key indexes, table comments, and ALTER TABLE extensions.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. service_categories (Parent table)
-- -----------------------------------------------------------------------------
CREATE TABLE service_categories (
    category_id   INTEGER GENERATED ALWAYS AS IDENTITY,
    category_name VARCHAR(100) NOT NULL,
    description   TEXT,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_service_categories PRIMARY KEY (category_id),
    CONSTRAINT uq_service_categories_category_name UNIQUE (category_name)
);

-- -----------------------------------------------------------------------------
-- 2. customers (Parent table)
-- -----------------------------------------------------------------------------
CREATE TABLE customers (
    customer_id INTEGER GENERATED ALWAYS AS IDENTITY,
    full_name   VARCHAR(120) NOT NULL,
    phone       VARCHAR(20) NOT NULL,
    email       VARCHAR(150) NOT NULL,
    city        VARCHAR(80) NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_customers PRIMARY KEY (customer_id),
    CONSTRAINT uq_customers_phone UNIQUE (phone),
    CONSTRAINT uq_customers_email UNIQUE (email)
);

-- -----------------------------------------------------------------------------
-- 3. technicians (Parent table)
-- -----------------------------------------------------------------------------
CREATE TABLE technicians (
    technician_id INTEGER GENERATED ALWAYS AS IDENTITY,
    full_name     VARCHAR(120) NOT NULL,
    specialty     VARCHAR(100) NOT NULL,
    phone         VARCHAR(20) NOT NULL,
    hourly_rate   NUMERIC(10, 2) NOT NULL,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_technicians PRIMARY KEY (technician_id),
    CONSTRAINT uq_technicians_phone UNIQUE (phone),
    CONSTRAINT ck_technicians_hourly_rate CHECK (hourly_rate > 0)
);

-- -----------------------------------------------------------------------------
-- 4. services (Child of service_categories)
-- -----------------------------------------------------------------------------
CREATE TABLE services (
    service_id        INTEGER GENERATED ALWAYS AS IDENTITY,
    category_id       INTEGER NOT NULL,
    service_name      VARCHAR(150) NOT NULL,
    base_price        NUMERIC(10, 2) NOT NULL,
    estimated_minutes INTEGER NOT NULL,

    CONSTRAINT pk_services PRIMARY KEY (service_id),
    CONSTRAINT fk_services_service_categories FOREIGN KEY (category_id)
        REFERENCES service_categories (category_id)
        ON DELETE RESTRICT,
    CONSTRAINT ck_services_base_price CHECK (base_price >= 0),
    CONSTRAINT ck_services_estimated_minutes CHECK (estimated_minutes > 0)
);

-- -----------------------------------------------------------------------------
-- 5. requests (Child of customers and technicians; technician_id is nullable)
-- -----------------------------------------------------------------------------
CREATE TABLE requests (
    request_id    INTEGER GENERATED ALWAYS AS IDENTITY,
    customer_id   INTEGER NOT NULL,
    technician_id INTEGER,
    request_date  TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status        VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    address       TEXT NOT NULL,

    CONSTRAINT pk_requests PRIMARY KEY (request_id),
    CONSTRAINT fk_requests_customers FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_requests_technicians FOREIGN KEY (technician_id)
        REFERENCES technicians (technician_id)
        ON DELETE SET NULL,
    CONSTRAINT ck_requests_status CHECK (
        status IN ('PENDING', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED')
    )
);

-- -----------------------------------------------------------------------------
-- 6. request_items (Child of requests and services)
-- -----------------------------------------------------------------------------
CREATE TABLE request_items (
    item_id    INTEGER GENERATED ALWAYS AS IDENTITY,
    request_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    quantity   INTEGER NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL,

    CONSTRAINT pk_request_items PRIMARY KEY (item_id),
    CONSTRAINT fk_request_items_requests FOREIGN KEY (request_id)
        REFERENCES requests (request_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_request_items_services FOREIGN KEY (service_id)
        REFERENCES services (service_id)
        ON DELETE RESTRICT,
    CONSTRAINT ck_request_items_quantity CHECK (quantity > 0),
    CONSTRAINT ck_request_items_unit_price CHECK (unit_price >= 0)
);

-- -----------------------------------------------------------------------------
-- 7. payments (Child of requests)
-- -----------------------------------------------------------------------------
CREATE TABLE payments (
    payment_id     INTEGER GENERATED ALWAYS AS IDENTITY,
    request_id     INTEGER NOT NULL,
    amount         NUMERIC(10, 2) NOT NULL,
    payment_method VARCHAR(20) NOT NULL,
    payment_status VARCHAR(20) NOT NULL,
    paid_at        TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_payments PRIMARY KEY (payment_id),
    CONSTRAINT fk_payments_requests FOREIGN KEY (request_id)
        REFERENCES requests (request_id)
        ON DELETE RESTRICT,
    CONSTRAINT ck_payments_amount CHECK (amount > 0),
    CONSTRAINT ck_payments_payment_method CHECK (
        payment_method IN ('CARD', 'ONLINE', 'CASH')
    ),
    CONSTRAINT ck_payments_payment_status CHECK (
        payment_status IN ('PAID', 'FAILED', 'REFUNDED')
    )
);

-- -----------------------------------------------------------------------------
-- 8. reviews (Child of requests; 1-to-1 via UNIQUE constraint on request_id)
-- -----------------------------------------------------------------------------
CREATE TABLE reviews (
    review_id  INTEGER GENERATED ALWAYS AS IDENTITY,
    request_id INTEGER NOT NULL,
    rating     SMALLINT NOT NULL,
    comment    TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_reviews PRIMARY KEY (review_id),
    CONSTRAINT uq_reviews_request_id UNIQUE (request_id),
    CONSTRAINT fk_reviews_requests FOREIGN KEY (request_id)
        REFERENCES requests (request_id)
        ON DELETE CASCADE,
    CONSTRAINT ck_reviews_rating CHECK (rating BETWEEN 1 AND 5)
);

-- =============================================================================
-- Foreign Key Indexes
-- =============================================================================
CREATE INDEX idx_requests_customer_id ON requests (customer_id);
CREATE INDEX idx_requests_technician_id ON requests (technician_id);
CREATE INDEX idx_request_items_request_id ON request_items (request_id);
CREATE INDEX idx_payments_request_id ON payments (request_id);

-- =============================================================================
-- Table Comments
-- =============================================================================
COMMENT ON TABLE service_categories IS 'Lookup table storing service categories and their active status.';
COMMENT ON TABLE customers IS 'Stores registered customers requesting technical repair services.';
COMMENT ON TABLE technicians IS 'Stores certified technicians, specialties, hourly rates, and employment status.';
COMMENT ON TABLE services IS 'Catalog of repair and maintenance services linked to categories.';
COMMENT ON TABLE requests IS 'Customer service requests tracking assigned technician, status, and service address.';
COMMENT ON TABLE request_items IS 'Line items detailing services performed and unit prices per request.';
COMMENT ON TABLE payments IS 'Financial payment transactions recorded against service requests.';
COMMENT ON TABLE reviews IS 'Customer satisfaction ratings and feedback for completed service requests.';

-- =============================================================================
-- Schema Evolution (ALTER TABLE)
-- =============================================================================
ALTER TABLE technicians
    ADD COLUMN hire_date DATE;

ALTER TABLE technicians
    ADD CONSTRAINT ck_technicians_hire_date CHECK (hire_date <= CURRENT_DATE);
