-- ============================================================================
-- PostgreSQL pg_stat_statements Query Execution Details Guide
-- ============================================================================
-- This file contains queries to analyze query execution details using
-- the pg_stat_statements extension in PostgreSQL
-- ============================================================================

-- ============================================================================
-- STEP 1: Enable pg_stat_statements Extension
-- ============================================================================

-- First, add pg_stat_statements to shared_preload_libraries in postgresql.conf:
-- shared_preload_libraries = 'pg_stat_statements'
-- Then restart PostgreSQL

-- Create the extension (run as superuser):
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- ============================================================================
-- STEP 2: Basic Query Execution Statistics
-- ============================================================================

-- View all query statistics (basic overview)
SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time,
    min_exec_time,
    stddev_exec_time
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;

-- ============================================================================
-- STEP 3: Most Time-Consuming Queries
-- ============================================================================

-- Top queries by total execution time
SELECT 
    LEFT(query, 100) AS query_preview,
    calls,
    ROUND(total_exec_time::numeric, 2) AS total_time_ms,
    ROUND(mean_exec_time::numeric, 2) AS avg_time_ms,
    ROUND(max_exec_time::numeric, 2) AS max_time_ms,
    ROUND((100 * total_exec_time / SUM(total_exec_time) OVER ())::numeric, 2) AS pct_total_time
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY total_exec_time DESC
LIMIT 20;

-- ============================================================================
-- STEP 4: Slowest Queries (by average execution time)
-- ============================================================================

-- Queries with highest average execution time
SELECT 
    LEFT(query, 100) AS query_preview,
    calls,
    ROUND(mean_exec_time::numeric, 2) AS avg_time_ms,
    ROUND(max_exec_time::numeric, 2) AS max_time_ms,
    ROUND(min_exec_time::numeric, 2) AS min_time_ms,
    ROUND(stddev_exec_time::numeric, 2) AS stddev_time_ms
FROM pg_stat_statements
WHERE calls > 0
  AND query NOT LIKE '%pg_stat_statements%'
ORDER BY mean_exec_time DESC
LIMIT 20;

-- ============================================================================
-- STEP 5: Most Frequently Executed Queries
-- ============================================================================

-- Queries executed most often
SELECT 
    LEFT(query, 100) AS query_preview,
    calls,
    ROUND(total_exec_time::numeric, 2) AS total_time_ms,
    ROUND(mean_exec_time::numeric, 2) AS avg_time_ms,
    ROUND((100 * calls / SUM(calls) OVER ())::numeric, 2) AS pct_of_calls
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY calls DESC
LIMIT 20;

-- ============================================================================
-- STEP 6: I/O Statistics
-- ============================================================================

-- Queries with highest I/O operations
SELECT 
    LEFT(query, 100) AS query_preview,
    calls,
    shared_blks_hit,
    shared_blks_read,
    shared_blks_dirtied,
    shared_blks_written,
    local_blks_hit,
    local_blks_read,
    local_blks_dirtied,
    local_blks_written,
    temp_blks_read,
    temp_blks_written,
    ROUND((shared_blks_hit::numeric / NULLIF(shared_blks_hit + shared_blks_read, 0) * 100)::numeric, 2) AS cache_hit_ratio
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY (shared_blks_read + shared_blks_written) DESC
LIMIT 20;

-- ============================================================================
-- STEP 7: Cache Hit Ratio Analysis
-- ============================================================================

-- Queries with poor cache hit ratios (indicating disk I/O issues)
SELECT 
    LEFT(query, 100) AS query_preview,
    calls,
    shared_blks_hit,
    shared_blks_read,
    ROUND((shared_blks_hit::numeric / NULLIF(shared_blks_hit + shared_blks_read, 0) * 100)::numeric, 2) AS cache_hit_ratio_pct,
    ROUND(mean_exec_time::numeric, 2) AS avg_time_ms
FROM pg_stat_statements
WHERE shared_blks_hit + shared_blks_read > 0
  AND query NOT LIKE '%pg_stat_statements%'
ORDER BY cache_hit_ratio_pct ASC
LIMIT 20;

-- ============================================================================
-- STEP 8: Temporary File Usage
-- ============================================================================

-- Queries using temporary files (may indicate insufficient work_mem)
SELECT 
    LEFT(query, 100) AS query_preview,
    calls,
    temp_blks_read,
    temp_blks_written,
    ROUND(mean_exec_time::numeric, 2) AS avg_time_ms,
    ROUND(max_exec_time::numeric, 2) AS max_time_ms
FROM pg_stat_statements
WHERE temp_blks_read > 0 OR temp_blks_written > 0
  AND query NOT LIKE '%pg_stat_statements%'
ORDER BY (temp_blks_read + temp_blks_written) DESC
LIMIT 20;

-- ============================================================================
-- STEP 9: Query Planning Statistics
-- ============================================================================

-- Queries with planning information (PostgreSQL 13+)
SELECT 
    LEFT(query, 100) AS query_preview,
    calls,
    total_plan_time,
    mean_plan_time,
    ROUND(total_exec_time::numeric, 2) AS total_exec_time_ms,
    ROUND(mean_exec_time::numeric, 2) AS mean_exec_time_ms,
    ROUND((100 * total_plan_time / NULLIF(total_plan_time + total_exec_time, 0))::numeric, 2) AS plan_time_pct
FROM pg_stat_statements
WHERE calls > 0
  AND query NOT LIKE '%pg_stat_statements%'
ORDER BY total_plan_time DESC
LIMIT 20;

-- ============================================================================
-- STEP 10: Comprehensive Query Analysis
-- ============================================================================

-- Complete query execution details with all metrics
SELECT 
    LEFT(query, 80) AS query_preview,
    calls,
    ROUND(total_exec_time::numeric, 2) AS total_time_ms,
    ROUND(mean_exec_time::numeric, 2) AS avg_time_ms,
    ROUND(max_exec_time::numeric, 2) AS max_time_ms,
    ROUND(stddev_exec_time::numeric, 2) AS stddev_time_ms,
    shared_blks_hit,
    shared_blks_read,
    shared_blks_dirtied,
    shared_blks_written,
    temp_blks_read,
    temp_blks_written,
    ROUND((shared_blks_hit::numeric / NULLIF(shared_blks_hit + shared_blks_read, 0) * 100)::numeric, 2) AS cache_hit_ratio_pct,
    ROUND((100 * total_exec_time / SUM(total_exec_time) OVER ())::numeric, 2) AS pct_total_time
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY total_exec_time DESC
LIMIT 30;

-- ============================================================================
-- STEP 11: Find Specific Query Pattern
-- ============================================================================

-- Search for queries containing specific text (e.g., table name)
SELECT 
    query,
    calls,
    ROUND(total_exec_time::numeric, 2) AS total_time_ms,
    ROUND(mean_exec_time::numeric, 2) AS avg_time_ms,
    ROUND(max_exec_time::numeric, 2) AS max_time_ms
FROM pg_stat_statements
WHERE query ILIKE '%your_table_name%'
  OR query ILIKE '%your_pattern%'
ORDER BY total_exec_time DESC;

-- ============================================================================
-- STEP 12: Reset Statistics
-- ============================================================================

-- Reset all statistics (use with caution - requires superuser)
-- SELECT pg_stat_statements_reset();

-- Reset statistics for a specific query
-- SELECT pg_stat_statements_reset(userid, dbid, queryid);

-- ============================================================================
-- STEP 13: Query by Database
-- ============================================================================

-- Get query statistics grouped by database
SELECT 
    d.datname AS database_name,
    COUNT(*) AS query_count,
    SUM(s.calls) AS total_calls,
    ROUND(SUM(s.total_exec_time)::numeric, 2) AS total_time_ms,
    ROUND(AVG(s.mean_exec_time)::numeric, 2) AS avg_time_ms
FROM pg_stat_statements s
JOIN pg_database d ON s.dbid = d.oid
WHERE s.query NOT LIKE '%pg_stat_statements%'
GROUP BY d.datname
ORDER BY total_time_ms DESC;

-- ============================================================================
-- STEP 14: Query by User
-- ============================================================================

-- Get query statistics grouped by user
SELECT 
    u.usename AS username,
    COUNT(*) AS query_count,
    SUM(s.calls) AS total_calls,
    ROUND(SUM(s.total_exec_time)::numeric, 2) AS total_time_ms,
    ROUND(AVG(s.mean_exec_time)::numeric, 2) AS avg_time_ms
FROM pg_stat_statements s
JOIN pg_user u ON s.userid = u.usesysid
WHERE s.query NOT LIKE '%pg_stat_statements%'
GROUP BY u.usename
ORDER BY total_time_ms DESC;

-- ============================================================================
-- STEP 15: Normalized Query Analysis
-- ============================================================================

-- View normalized queries (useful for finding similar query patterns)
SELECT 
    LEFT(query, 100) AS normalized_query,
    COUNT(*) AS query_variations,
    SUM(calls) AS total_calls,
    ROUND(SUM(total_exec_time)::numeric, 2) AS total_time_ms,
    ROUND(AVG(mean_exec_time)::numeric, 2) AS avg_time_ms
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat_statements%'
GROUP BY query
HAVING COUNT(*) > 1
ORDER BY total_time_ms DESC
LIMIT 20;

-- ============================================================================
-- TIPS:
-- ============================================================================
-- 1. pg_stat_statements tracks queries across all databases
-- 2. Statistics accumulate over time until reset
-- 3. The extension has a limit on number of queries tracked (default: 5000)
-- 4. Increase pg_stat_statements.max to track more queries
-- 5. Use pg_stat_statements_reset() periodically to clear old data
-- 6. Query text is normalized (parameters replaced with $1, $2, etc.)
-- 7. For PostgreSQL 13+, planning time is also tracked separately
-- ============================================================================
