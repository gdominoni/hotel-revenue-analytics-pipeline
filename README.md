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

### 7. Feature Engineering: Length of Stay (LOS) Baseline
*   **Action:** Restructured the core schema to calculate and inject a dedicated `total_nights` dimension, placing it physically after the split weekend and weekday night components.
*   **Commercial Logic:** Forcing a machine learning model or reporting tool to perform inline math across every query introduces computational friction. By storing a native, consolidated length of stay column, we provide downstream analytics pipelines with a clean baseline metric for tracking reservation duration.

---

## 📈 Generating Historical Operational Views

With a pristine reservation table established, the pipeline shifts focus from flat rows to dynamic, time-series operations. Three independent operational views were generated to reconstruct the historical state of the hotel and real-time market activity:

### 1. Physical Occupancy & Revenue History (The House State)
*   **Action:** Utilized a calendar spine array join to map out the exact arrival-to-departure footprint of every single booking.
*   **Commercial Logic:** Standard reservation dumps only show check-in dates and lengths of stay, completely hiding the "stay-over" guests who are already occupying beds. This process uncovers the true, daily physical occupancy and approximate room revenue generated by non-canceled bookings, resolving the multi-night overlapping stay blind spot.

### 2. Arrival-Date Pickup Pace (The Lead-Time Curve)
*   **Action:** Reconstructed historical arrival cohorts by measuring how many active reservations had already trickled into the database at specific milestones (90, 60, 30, 14, and 7 days out from arrival). Simultaneously, it calculated the final cumulative cancellation rate for each arrival date.
*   **Commercial Logic:** This isolates specific demand patterns—such as early-booking corporate/tour groups versus high-velocity, short-lead transient retail bookings—allowing downstream pipelines to recognize the behavioral differences in booking momentum.

### 3. Daily Booking Activity Volume (The Daily Workload)
*   **Action:** Aggregated the absolute volume of transactions processed by the reservations department on any given calendar date, broken down by hotel and market segment. It isolates exactly how many new active bookings were created versus how many cancellations were processed on that day.
*   **Commercial Logic:** This acts as a real-time market sentiment or "panic indicator." If a specific market segment suddenly experiences a massive wave of cancellations on a single afternoon, this dimension captures that immediate downward pressure regardless of when those guests were originally scheduled to arrive.

---

## 🧬 Multidimensional Feature Merging

*   **Action:** Combined individual guest reservations with our three historical operational views into a single, flat, high-performance table named `ml_ready_bookings`. Applied strict database `COALESCE` safety nets during the join process to automatically replace missing values or dead transactional days with true numerical zeros.
*   **Data Engineering Logic:** Machine learning models cannot natively process overlapping time windows or cross-reference separate historical tables on the fly. Furthermore, missing values (NULL states) will cause Python algorithms to crash during training. By merging the "Arrival Day House State," the "Lead-Time Pickup Pace Curve," and the "Booking Day Market Activity" directly onto individual reservation rows, we provide the machine learning model with full, multi-layered operational context while keeping the dataset structurally pristine and ready for modeling.

