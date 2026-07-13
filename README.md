# hotel-revenue-analytics-pipeline

**TASK**:
Dynamic Inventory Protection: A data engineering and commercial analytics case study utilizing SQL and Python to reconstruct daily reservation timelines, analyze market segment cancellation rate, and optimize hotel strategy by market segment and seasonality.

DATASET:
Opensourced

## 🧼 Data Cleaning & Governance Rules Applied
Before performing any structural data calculations or revenue mapping, a strict data cleaning protocol was established in `00_data_cleaning_and_audit.sql`:
1. **DROP USELESS DATA** We dropped assigned_room_type and reservation_status (since is_canceled already explicitly tracks the target variable, and assigned room type refers to what happens to the customer at check in, which is irrelevant for our purpose)
2 - **check for null values in all the columns** Since the null values have been substituded with the string "NULL", we deleted the string
4 - **check for reservations with 0 adults (impossible)** Changed to 1
5 - **check for ouliners:** more than 2 children and/or infant (changed to 2, as 2 is supposed to be the maximum allowed in the rooms)
6 - **check that all the cathegorical data is set as string**
7 - **check the distinct values of all columns**, to identify data-entry errors (For example, the wrong name of a market segment)
