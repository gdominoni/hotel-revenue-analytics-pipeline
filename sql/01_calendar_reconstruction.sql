-- ============================================================================
-- PROJECT: Dynamic Inventory Protection
-- STEP 01: Calendar Reconstruction (Part 1 - Date Consolidation)
-- OBJECTIVE: Build standard DATE structures for arrival and booking timestamps,
--            and clean up redundant split calendar columns.
-- ============================================================================

-- 1. Add new structural DATE columns to the table schema
ALTER TABLE `giovannidominoni.hotel_case.bookings`
ADD COLUMN IF NOT EXISTS arrival_date DATE,
ADD COLUMN IF NOT EXISTS booking_date DATE;

-- 2. Synthesize the true arrival_date from split columns
UPDATE `giovannidominoni.hotel_case.bookings`
SET arrival_date = PARSE_DATE(
  '%Y-%B-%d', 
  CONCAT(CAST(arrival_date_year AS STRING), '-', arrival_date_month, '-', CAST(arrival_date_day_of_month AS STRING))
)
WHERE arrival_date_year IS NOT NULL;

-- 3. Calculate the true booking_date (reservation date) using lead_time
UPDATE `giovannidominoni.hotel_case.bookings`
SET booking_date = DATE_SUB(arrival_date, INTERVAL lead_time DAY)
WHERE arrival_date IS NOT NULL;

-- 4. Purge the redundant week number column
ALTER TABLE `giovannidominoni.hotel_case.bookings`
DROP COLUMN IF EXISTS arrival_date_week_number;

-- 5. For the sake of readibility, we reordered the columns
    -- 5a. first I created a back-up file
    CREATE TABLE `giovannidominoni.hotel_case.bookings_backup_pre_reorder` AS 
    SELECT * FROM `giovannidominoni.hotel_case.bookings`;

CREATE OR REPLACE TABLE `giovannidominoni.hotel_case.bookings` AS
SELECT
  hotel,
  lead_time,
  booking_date,
  arrival_date,
  stays_in_weekend_nights,
  stays_in_week_nights,
  adults,
  children,
  babies,
  country,
  adr,
  is_canceled,
  is_repeated_guest,
  previous_cancellations,
  previous_bookings_not_canceled,
  reserved_room_type,
  booking_changes,
  deposit_type,
  agent,
  company,
  days_in_waiting_list,
  customer_type,
  market_segment,
  distribution_channel,
  required_car_parking_spaces,
  total_of_special_requests,
  meal
  
FROM `giovannidominoni.hotel_case.bookings`;

