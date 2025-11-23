create or replace table `datamart.fact_transactions_trades` as 

with raw_trades as (
  select
    trade_id
    ,user_id
    ,token_id
    ,side
    ,cast(price_usd as bignumeric) trade_price_usd
    ,cast(quantity as bignumeric) trade_quantity
    ,status
    ,datetime(
          parse_timestamp('%Y-%m-%d %H:%M:%S', trade_created_time),
          'Asia/Jakarta'
      ) AS trade_created_time -- convert to Jakarta / WIB Time
    ,datetime(
          parse_timestamp('%Y-%m-%d %H:%M:%S', trade_updated_time),
          'Asia/Jakarta'
      ) AS trade_updated_time -- convert to Jakarta / WIB Time
    ,row_number() over(partition by trade_id order by 
      datetime(
          parse_timestamp('%Y-%m-%d %H:%M:%S', trade_created_time),
          'Asia/Jakarta'
      )) rn
  from  `raw_transaction.raw_trades`
  where status = 'FILLED'
)

select
  trade_id
  ,user_id
  ,token_id
  ,side
  ,trade_price_usd
  ,trade_quantity
  ,trade_price_usd * trade_quantity trade_value_usd
  ,status
  ,trade_created_time 
  ,trade_updated_time
from raw_trades
where rn = 1 -- to ensure trade_id is unique and get the early one