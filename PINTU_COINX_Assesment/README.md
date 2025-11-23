# PINTU Data Analyst Assessment - CoinX Data Solution

This repository contains the end-to-end data transformation and modeling solution designed to address the leadership's primary concerns regarding **Trading Concentration Risk**, **User Retention**, and **Data Governance**.

The final data architecture uses a **Star Schema** to provide performant, clear data for reporting via BigQuery.

## 🚀 Solution Architecture Summary

| Layer | Purpose | Key Deliverable | Location |
| :--- | :--- | :--- | :--- |
| **Source** | Raw data storage (untransformed strings). | `raw_trades`, `raw_p2p_transfers` | `raw_transaction` schema |
| **Model** | Cleaned, transformed, and enriched data mart. | `fact_transactions_p2p_transfers`  `fact_transactions_trades`, `dim_users`, `dim_tokens` | `data_mart` schema |
| **Governance**| Data quality and compliance policies. | **Anomaly Detection ($P_{99.9}$)** | `docs/Data_Governance_Plan.md` |

## 📦 Repository Contents

1.  **SQL Models:** All `CREATE OR REPLACE TABLE` statements.
    * **Location:** `sql/` folder
2.  **Documentation:** Detailed descriptions of the data flow and rules.
    * **Location:** `docs/` folder
3.  **Visual Blueprint:** Logical design of the data mart.
    * **Location:** `docs/ERD.md`

## ⚠️ Note on SQL Dialect

All transformation and analytical queries provided in this repository are written in **Google BigQuery Standard SQL** dialect.

This specific language is used to leverage proprietary functions necessary for the data governance policies, including:

* **Data Type Handling:** `PARSE_TIMESTAMP`, `DATETIME`, and `BIGNUMERIC`.
* **Anomaly Detection:** `APPROX_QUANTILES`.
* **Time Series Analysis:** `DATE_TRUNC`.

## Report / Dashboard Layout

Google Sheets : https://docs.google.com/spreadsheets/d/1RjQ0Ldk9_urFU4XStiXmTGO53sxSHVXQcelkWuMfiHU/edit?gid=499880761#gid=499880761