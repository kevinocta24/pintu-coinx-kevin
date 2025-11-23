# Entity-Relationship Diagram (ERD) & Star Schema Definition

The data mart is modeled as a **Star Schema**, optimized for analytical query performance (e.g., fast lookups for filtering and aggregation).



## Fact Tables (Events)

| Table Name | Primary Key (PK) | Foreign Keys (FKs) | Key Metric |
| :--- | :--- | :--- | :--- |
| **Fact_Transactions_P2P_Transfers** | `transfer_id` | `user_id`, `token_id` | `transfer_value_usd` (Core Revenue Metric) |
| **Fact_Transactions_Trades** | `trade_id` | `sender_id`, `receiver_id`, `token_id` | `trade_value_usd` (Compliance Metric) |

## Dimension Tables (Context)

| Table Name | Primary Key (PK) |
| :--- | :--- |
| **Dim_Users** | `user_id` |
| **Dim_Tokens** | `token_id` |
| **Dim_Date** | `date_key` |



