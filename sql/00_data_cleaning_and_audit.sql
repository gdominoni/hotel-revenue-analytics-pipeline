-- ============================================================================
-- PROJECT: Dynamic Inventory Protection
-- STEP 00: Schema Optimization & Redundancy Purge
-- OBJECTIVE: Permanently drop redundant columns and unneeded tracking vectors 
--            to streamline the core booking database before audit verification.
-- ============================================================================

-- 1. Purge redundant target variables and operational assignment columns
ALTER TABLE `giovannidominoni.hotel_case.bookings` 
DROP COLUMN IF EXISTS assigned_room_type,
DROP COLUMN IF EXISTS reservation_status;

-- 2. Clear out fake text strings AND clean up dirty whitespace in one single pass
UPDATE `giovannidominoni.hotel_case.bookings`
SET
  hotel = IF(UPPER(TRIM(hotel)) IN ('NULL', 'N/A', 'UNKNOWN', ''), NULL, TRIM(hotel)),
  arrival_date_month = IF(UPPER(TRIM(arrival_date_month)) IN ('NULL', 'N/A', 'UNKNOWN', ''), NULL, TRIM(arrival_date_month)),
  meal = IF(UPPER(TRIM(meal)) IN ('NULL', 'N/A', 'UNKNOWN', ''), NULL, TRIM(meal)),
  country = IF(UPPER(TRIM(country)) IN ('NULL', 'N/A', 'UNKNOWN', ''), NULL, TRIM(country)),
  market_segment = IF(UPPER(TRIM(market_segment)) IN ('NULL', 'N/A', 'UNKNOWN', 'UNDEFINED', ''), NULL, TRIM(market_segment)),
  distribution_channel = IF(UPPER(TRIM(distribution_channel)) IN ('NULL', 'N/A', 'UNKNOWN', 'UNDEFINED', ''), NULL, TRIM(distribution_channel)),
  reserved_room_type = IF(UPPER(TRIM(reserved_room_type)) IN ('NULL', 'N/A', 'UNKNOWN', ''), NULL, TRIM(reserved_room_type)),
  deposit_type = IF(UPPER(TRIM(deposit_type)) IN ('NULL', 'N/A', 'UNKNOWN', ''), NULL, TRIM(deposit_type)),
  agent = IF(UPPER(TRIM(agent)) IN ('NULL', 'N/A', 'UNKNOWN', ''), NULL, TRIM(agent)),
  company = IF(UPPER(TRIM(company)) IN ('NULL', 'N/A', 'UNKNOWN', ''), NULL, TRIM(company)),
  customer_type = IF(UPPER(TRIM(customer_type)) IN ('NULL', 'N/A', 'UNKNOWN', ''), NULL, TRIM(customer_type))
WHERE 
  -- Find rows that either have a fake NULL string OR have untrimmed trailing/leading spaces
  UPPER(TRIM(hotel)) IN ('NULL', 'N/A', 'UNKNOWN', '') OR hotel != TRIM(hotel)
  OR UPPER(TRIM(arrival_date_month)) IN ('NULL', 'N/A', 'UNKNOWN', '') OR arrival_date_month != TRIM(arrival_date_month)
  OR UPPER(TRIM(meal)) IN ('NULL', 'N/A', 'UNKNOWN', '') OR meal != TRIM(meal)
  OR UPPER(TRIM(country)) IN ('NULL', 'N/A', 'UNKNOWN', '') OR country != TRIM(country)
  OR UPPER(TRIM(market_segment)) IN ('NULL', 'N/A', 'UNKNOWN', 'UNDEFINED', '') OR market_segment != TRIM(market_segment)
  OR UPPER(TRIM(distribution_channel)) IN ('NULL', 'N/A', 'UNKNOWN', 'UNDEFINED', '') OR distribution_channel != TRIM(distribution_channel)
  OR UPPER(TRIM(reserved_room_type)) IN ('NULL', 'N/A', 'UNKNOWN', '') OR reserved_room_type != TRIM(reserved_room_type)
  OR UPPER(TRIM(deposit_type)) IN ('NULL', 'N/A', 'UNKNOWN', '') OR deposit_type != TRIM(deposit_type)
  OR UPPER(TRIM(agent)) IN ('NULL', 'N/A', 'UNKNOWN', '') OR agent != TRIM(agent)
  OR UPPER(TRIM(company)) IN ('NULL', 'N/A', 'UNKNOWN', '') OR company != TRIM(company)
  OR UPPER(TRIM(customer_type)) IN ('NULL', 'N/A', 'UNKNOWN', '') OR customer_type != TRIM(customer_type);

-- 3. Correct logical entries where adults count equals 0
UPDATE `giovannidominoni.hotel_case.bookings`
SET adults = 1
WHERE adults = 0;

-- ----------------------------------------------------------------------------
-- 4. Correct Extreme Family Outliers
-- DESIGN NOTE: Ideally, before capping children and babies, we should verify 
--              these counts against the "maximum allowed occupancy" for each 
--              reserved_room_type. However, because our dataset does not contain 
--              a room capacity dimension, we must treat extreme counts as 
--              data-entry errors. 
--              To prevent these outliers from distorting downstream demand/pricing 
--              models while keeping the bookings valid, we cap both children and 
--              babies at a logical limit of 2.
-- ----------------------------------------------------------------------------
UPDATE `giovannidominoni.hotel_case.bookings`
SET 
  children = IF(children > 2, 2, children),
  babies = IF(babies > 2, 2, babies)
WHERE 
  children > 2 
  OR babies > 2;

-- 5. Ensure all categorical columns are explicitly cast to STRING
-- This handles columns that might have mistakenly imported as numeric types (e.g., agent, company)
ALTER TABLE `giovannidominoni.hotel_case.bookings`
  ALTER COLUMN hotel SET DATA TYPE STRING,
  ALTER COLUMN arrival_date_month SET DATA TYPE STRING,
  ALTER COLUMN meal SET DATA TYPE STRING,
  ALTER COLUMN country SET DATA TYPE STRING,
  ALTER COLUMN market_segment SET DATA TYPE STRING,
  ALTER COLUMN distribution_channel SET DATA TYPE STRING,
  ALTER COLUMN reserved_room_type SET DATA TYPE STRING,
  ALTER COLUMN deposit_type SET DATA TYPE STRING,
  ALTER COLUMN customer_type SET DATA TYPE STRING,
  -- Agent and Company are IDs but behave purely as categories
  ALTER COLUMN agent SET DATA TYPE STRING,
  ALTER COLUMN company SET DATA TYPE STRING;

-- 6. Audit categorical values to identify manual entry errors/typos
SELECT 'market_segment' AS column_name, market_segment AS distinct_value, COUNT(*) as frequency 
FROM `giovannidominoni.hotel_case.bookings` GROUP BY market_segment

UNION ALL

SELECT 'distribution_channel', distribution_channel, COUNT(*) 
FROM `giovannidominoni.hotel_case.bookings` GROUP BY distribution_channel

UNION ALL

SELECT 'meal', meal, COUNT(*) 
FROM `giovannidominoni.hotel_case.bookings` GROUP BY meal

UNION ALL

SELECT 'deposit_type', deposit_type, COUNT(*) 
FROM `giovannidominoni.hotel_case.bookings` GROUP BY deposit_type

UNION ALL

SELECT 'customer_type', customer_type, COUNT(*) 
FROM `giovannidominoni.hotel_case.bookings` GROUP BY customer_type
ORDER BY column_name, frequency DESC;

-- 7. Harmonize Categorical Values & Operational Labels
-- Consolidate Transient sub-types and standardize room-only meal designations
UPDATE `giovannidominoni.hotel_case.bookings`
SET
  -- For our purpose, Transient-Party is simply transient.
  customer_type = IF(customer_type = 'Transient-Party', 'Transient', customer_type),
  -- "Undefined" is most likely going to be "SC"
  meal = IF(meal = 'Undefined', 'SC', meal)
  WHERE 
  customer_type = 'Transient-Party' 
  OR meal = 'Undefined';



