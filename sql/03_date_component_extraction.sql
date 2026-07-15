-- ============================================================================
-- PROJECT: Dynamic Inventory Protection
-- STEP 04: Date Component Extraction
-- OBJECTIVE: Extract raw chronological parts from the arrival date and 
--            append them to the master table for downstream modeling.
-- ============================================================================

CREATE OR REPLACE TABLE `giovannidominoni.hotel_case.ml_ready_bookings` AS
SELECT 
  *,
  -- 1. Numeric Month (1 to 12)
  EXTRACT(MONTH FROM SAFE_CAST(arrival_date AS DATE)) AS arrival_month,
  
  -- 2. Numeric Day of Week (1 to 7, where 1 is Sunday)
  EXTRACT(DAYOFWEEK FROM SAFE_CAST(arrival_date AS DATE)) AS arrival_day_of_week,
  
  -- 3. Week of Year (1 to 53)
  EXTRACT(WEEK FROM SAFE_CAST(arrival_date AS DATE)) AS arrival_week_of_year,
  
  -- 4. Quarter of Year (1 to 4)
  EXTRACT(QUARTER FROM SAFE_CAST(arrival_date AS DATE)) AS arrival_quarter,

  -- 5. Weekend Arrival Indicator (Binary: 1 if Friday [6] or Saturday [7], 0 otherwise)
  CASE 
    WHEN EXTRACT(DAYOFWEEK FROM SAFE_CAST(arrival_date AS DATE)) IN (6, 7) THEN 1 
    ELSE 0 
  END AS is_arrival_weekend

FROM `giovannidominoni.hotel_case.ml_ready_bookings`;
