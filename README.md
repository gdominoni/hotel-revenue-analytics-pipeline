# hotel-revenue-analytics-pipeline

**TASK**:
Dynamic Inventory Protection: A data engineering and commercial analytics case study utilizing SQL and Python to reconstruct daily reservation timelines, analyze market segment cancellation rates, and optimize hotel strategy by market segment and seasonality.

**DATASET**:
Open-sourced (Hotel Booking Demand dataset)

---

## 🧼 Data Cleaning & Governance Rules Applied

Before performing any structural data calculations or revenue mapping, a strict data-cleaning and auditing protocol was established in `00_data_cleaning_and_audit.sql`. This ensures maximum data integrity for downstream machine learning and reporting pipelines.

### 1. Eliminating Target Leakage & Redundant Columns
*   **Action**: Permanently dropped `assigned_room_type` and `reservation_status` using `ALTER TABLE`.
*   **Commercial Logic**: `is_canceled` already explicitly tracks our target variable. `reservation_status` is a duplicate of this state, and `assigned_room_type` is an operational event determined at physical check-in. Including them would introduce severe **data leakage** and artificially inflate downstream machine learning models.

### 2. Standardizing Empty States & Eliminating White Spaces
*   **Action**: Replaced literal string artifacts like `'NULL'`, `'N/A'`, `'UNKNOWN'`, and empty spaces `''` with true system database `NULL` states across all categorical columns. Simultaneously applied `TRIM()` to strip leading/trailing spaces from valid values.
*   **Operational Logic**: In a production environment, messy string variants (like `" PRT"` vs `"PRT"`) split identical entities. Standardizing them into single-pass database `NULL` values allows Python/Pandas to easily handle missing values using standard `NaN` protocols.

### 3. Resolving Logical Operational Anomalies
*   **Action**: Swept the dataset for records with `adults = 0` and updated them to `1`.
*   **Commercial Logic**: Legally and operationally, a transient reservation contract cannot exist without at least one primary adult guest. Upgrading these ghost bookings to `1` preserves the financial transaction records while resolving a critical business logic error.

### 4. Auditing & Capping Extreme Family Outliers
*   **Action**: Identified and capped extreme counts where `children > 2` or `babies > 2` down to a logical threshold of `2`.
*   **Commercial Logic**: While real-world validation would ideally check these values against a physical room-capacity database, our raw table lack a maximum occupancy dimension. To prevent these massive outliers from heavily skewing family room demand models, we cap them conditionally (e.g., a booking with 4 children and 0 babies is capped at 2 children and 0 babies, without fabricating babies).

### 5. Enforcing Strict Schema Types
*   **Action**: Explicitly forced all nominal/categorical fields—specifically numerical identifiers like `agent` and `company`—to the `STRING` data type.
*   **Data Engineering Logic**: If ID numbers are left as integers, algorithms will mistakenly treat them as continuous, scale-dependent mathematical variables rather than distinct categorical entities.

### 6. Harmonizing Nominal Categories
After running comprehensive `UNION ALL` distinct-value audits, we identified and resolved several inconsistent categorical naming conventions:
*   **Customer Type**: Standardized and merged `Transient-Party` bookings directly into `Transient`. While they belong to loosely associated groups, their transaction, cancellation, and payment dynamics behave as individual retail guests.
*   **Meal Plans**: Standardized `Undefined` meal records into `SC` (Self-Catering). This aligns the dataset with standard European hospitality codes, eliminating ambiguous classifications while maintaining clean, operational terminology.
