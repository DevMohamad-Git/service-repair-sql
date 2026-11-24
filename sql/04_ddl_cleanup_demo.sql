-- =============================================================================
-- File: sql/04_ddl_cleanup_demo.sql
-- Database: service_repair_db (PostgreSQL 18)
-- Description: Safe DDL demonstration creating a temporary log table,
--              inserting and querying sample rows, and dropping only the demo
--              table without touching the 8 core tables.
-- =============================================================================

-- Purpose: Create a standalone temporary demo table with explicit primary key constraint.
CREATE TABLE temp_demo_log (
    log_id       INTEGER GENERATED ALWAYS AS IDENTITY,
    action_name  VARCHAR(100) NOT NULL,
    performed_by VARCHAR(100) NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_temp_demo_log PRIMARY KEY (log_id)
);

-- Purpose: Insert 3 sample audit log entries into the temporary demo table.
INSERT INTO temp_demo_log (action_name, performed_by) VALUES
    ('SCHEMA_VERIFICATION', 'admin_user'),
    ('SEED_DATA_AUDIT', 'db_instructor'),
    ('CLEANUP_DEMO_PREP', 'admin_user');

-- Purpose: Display all rows stored in temp_demo_log before dropping it.
SELECT
    log_id,
    action_name,
    performed_by,
    created_at
FROM temp_demo_log
ORDER BY log_id ASC;

-- Purpose: Remove the standalone temporary demo table without CASCADE or affecting core tables.
DROP TABLE temp_demo_log;
