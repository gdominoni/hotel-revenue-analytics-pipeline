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



