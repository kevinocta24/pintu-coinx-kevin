# Data Governance and Reliability Plan

This plan details the rules and transformation logic applied to the raw data to ensure the derived metrics are reliable and compliant for leadership reporting.

## 1. Data Quality Enforcement (Reliability)

| Policy | Raw Data Issue | Transformation Solution (BigQuery SQL) |
| :--- | :--- | :--- |
| **Standardization** | All time and financial fields are strings. | **Casting:** All `amount` and `price_usd` fields are cast to **`BIGNUMERIC`** to preserve maximum precision for financial calculations. All timestamps are cast to Jakarta `DATETIME`, except signup date which is assumed to be on Jakarta Time. |
| **Deduplication** | `raw_trades` may contain duplicate `trade_id`s. | **Golden Record Selection:** We use `ROW_NUMBER() OVER(PARTITION BY trade_id ORDER BY trade_created_time ASC)` to select and retain only the earliest, successful record (`rn = 1`) for inclusion in `Fact_Trades_Clean`. |
| **Failed Events** | Trades/Transfers can fail. | **Filtering:** Only records with `status = 'FILLED'` (Trades) or `status = 'SUCCESS'` (P2P Transfers) are promoted to the Fact tables. |
| **Data Completeness** | Missing trading days in `raw_trades` due to ingestion failure or platform downtime. | **Date Gap Audit:** Perform a **`LEFT JOIN`** of the continuous **`Dim_Date`** table against the daily unique dates in **`raw_trades`** to find and alert on any date that has no trade volume. |

Suggestion : Primary Key for each table better in format INT
---

## 2. Compliance and Valuation Rules

### A. USD Valuation (Addressing Missing Price Data)

The `raw_p2p_transfers` lack USD price, which is required for compliance screening.

* **Method:** We use `raw_trades` as a price feed to calculate a **Daily Volume-Weighted Average Price (VWAP)** for all tokens.
* **Gap Filling (LOCF + NOCB):** To handle days where no trades occurred for a token, we implement a combined **Last Observation Carried Forward (LOCF)** and **Next Observation Carried Backward (NOCB)** logic. The price is assigned using the following hierarchy:

    1.  **Primary Rule (LOCF):** We first attempt to use the **most recent available daily VWAP that occurred on or before** the transfer date.
    2.  **Fallback Rule (NOCB):** If the primary rule yields no price (e.g., the transfer occurred before the token's first trade), we use the **nearest available daily VWAP that occurred after** the transfer date.

    This method guarantees a highly reliable `transfer_value_usd` metric for compliance screening.

### B. Suspicious Transfer Anomaly Detection

This rule is designed to focus compliance resources only on the most statistically extreme transfers.

* **Definition:** A transfer is flagged as **`is_suspicious_transfer_dynamic_threshold`** if its calculated `transfer_value_usd` exceeds the **$99.9^{th}$ percentile ($P_{99.9}$) of all historical transfer values.**
* **Implementation:** The threshold is calculated dynamically using BigQuery's `APPROX_QUANTILES(transfer_value_usd, 1000)[OFFSET(999)]`.
* **Justification:** This dynamic approach ensures the rule scales with the platform's growth and volatility, preventing alert fatigue by focusing on true statistical outliers, not fixed dollar amounts.


* **Definition:** A transfer is flagged as **`is_suspicious_transfer_1500000_threshold`** if its calculated more than 1500000 based through the observation on the dataset.
* **Implementation:** The threshold is calculated dynamically using BigQuery's `transfer_value_usd >= 1500000`.
* **Justification:** This static threshold ensures consistency and strict adherence to current internal risk policy for fixed dollar reporting. While effective for immediate compliance, it requires mandatory manual adjustment in the next reporting period to proactively counter metric decay and maintain analytical relevance as the platform's overall volume grows.